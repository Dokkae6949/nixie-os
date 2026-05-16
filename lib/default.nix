{ lib, config, inputs, ... }:
let
  inherit (lib) mkOption types;

  # ── Base NixOS module ─────────────────────────────────────────────────
  # Included in every host. Declares the options.nixie namespace once so
  # feature modules can freely set config values without re-declaring options.
  baseNixosModule = { lib, ... }: {
    options.nixie = {
      # Freeform attrset: featureName -> resolved cfg.
      # Values are set by the framework; features read via config.nixie.features.<name>.
      features = mkOption {
        type    = types.lazyAttrsOf types.anything;
        default = {};
      };

      # ── Accumulation points ────────────────────────────────────────
      # Always declared. Features write here. Consumers read here.
      # If a consuming feature (e.g. impermanence) isn't active, writes
      # are just inert option values — no error, zero cost.
      impermanence = {
        directories = mkOption { type = types.listOf types.str;  default = []; };
        files       = mkOption { type = types.listOf types.str;  default = []; };
      };
      firewall = {
        tcp = mkOption { type = types.listOf types.port; default = []; };
        udp = mkOption { type = types.listOf types.port; default = []; };
      };
      backup.paths = mkOption { type = types.listOf types.str; default = []; };
    };
  };

  # ── Types ─────────────────────────────────────────────────────────────

  featureType = types.submodule {
    options = {
      # Option declarations for this feature. Evaluated via lib.evalModules
      # to apply defaults and type-check before being passed as `cfg`.
      # IMPORTANT: defaults cannot reference pkgs here. Use null as default
      # and handle the fallback inside the nixos/home body where pkgs is available.
      options = mkOption {
        type    = types.lazyAttrsOf types.raw;
        default = {};
      };
      # Function: { cfg, config, pkgs, lib, ... } -> NixOS module body (attrset).
      # cfg is the resolved, defaults-applied feature configuration.
      nixos = mkOption {
        type    = types.nullOr types.raw;
        default = null;
      };
      # Function: { cfg, pkgs, lib, ... } -> home-manager module body (attrset).
      # Same contract as nixos. config is home-manager's config here.
      home = mkOption {
        type    = types.nullOr types.raw;
        default = null;
      };
    };
  };

  profileType = types.submodule {
    options = {
      # Feature activations with option overrides.
      # features.firefox = {}          → enable with defaults
      # features.firefox.extensions = [...]  → enable with overrides
      features = mkOption {
        type    = types.lazyAttrsOf types.raw;
        default = {};
      };
      # System groups to add when this profile is active on a host.
      groups = mkOption {
        type    = types.listOf types.str;
        default = [];
      };
      # Inline home-manager module. Merged on top of "default" profile.
      home = mkOption {
        type    = types.nullOr types.raw;
        default = null;
      };
    };
  };

  userType = types.submodule {
    options = {
      uid     = mkOption { type = types.int; };
      shell   = mkOption { type = types.nullOr types.raw; default = null; };
      sshKeys = mkOption { type = types.listOf types.str; default = []; };
      groups  = mkOption { type = types.listOf types.str; default = []; };
      profiles = mkOption {
        type    = types.attrsOf profileType;
        default = {};
        description = ''
          Named personality configurations.
          "default" is always applied first if defined.
          Additional profiles compose on top via module merging.
        '';
      };
      # Escape hatch. Rarely needed — uid/shell/sshKeys/groups cover identity.
      # Use for: PAM rules, system-level systemd.user services, custom sudo policy.
      nixos = mkOption {
        type    = types.nullOr types.raw;
        default = null;
      };
    };
  };

  hostUserType = types.submodule {
    options = {
      # Profile names to activate. "default" is always prepended (if defined).
      profiles = mkOption {
        type    = types.listOf types.str;
        default = [];
      };
      # Additional groups for this user on this host only.
      # Useful when a host has hardware/services the user needs access to
      # without making it part of a reusable profile.
      groups = mkOption {
        type    = types.listOf types.str;
        default = [];
      };
      # Machine-specific home additions (wallpaper, monitor DPI, symlinks to
      # host-local paths). Applied last, so it can override profile home config.
      home = mkOption {
        type    = types.nullOr types.raw;
        default = null;
      };
    };
  };

  hostType = types.submodule {
    options = {
      system   = mkOption { type = types.str; default = "x86_64-linux"; };

      # Feature activations with inline option overrides.
      # features.bluetooth = {}             → defaults
      # features.postgresql.port = 5433     → override specific options
      features = mkOption {
        type    = types.lazyAttrsOf types.raw;
        default = {};
      };

      users = mkOption {
        type    = types.attrsOf hostUserType;
        default = {};
      };

      # Host-authoritative NixOS config. Applied last, wins over everything.
      nixos = mkOption { type = types.nullOr types.raw; default = null; };

      # Applied to ALL enrolled users via home-manager sharedModules.
      # Good for: machine-wide font scale, HiDPI, default themes, display config.
      home = mkOption { type = types.nullOr types.raw; default = null; };

      extraModules = mkOption { type = types.listOf types.raw; default = []; };
    };
  };

  # ── Helpers ───────────────────────────────────────────────────────────

  # All feature definitions (excludes the reserved users/hosts keys).
  allFeatures = lib.filterAttrs (n: _: !lib.elem n [ "users" "hosts" ]) config.nixie;

  enrolledUsersFor = hostCfg:
    lib.filterAttrs (n: _: hostCfg.users ? ${n}) config.nixie.users;

  # Evaluate a feature's options with the provided raw values, applying
  # declared defaults and type-checking. Returns a resolved cfg attrset.
  # Called at flake-eval time — type errors surface before nixos-rebuild.
  # Note: option defaults cannot reference pkgs (not available here).
  # Use null defaults and handle fallbacks in the feature body.
  resolveFeatureCfg = featureName: rawValues:
    let feature = allFeatures.${featureName};
    in
    if feature.options == {}
    then rawValues   # no options → pass through as-is
    else (lib.evalModules {
      modules =
        [ { options = feature.options; } ]
        ++ lib.optional (rawValues != {}) { config = rawValues; };
    }).config;

  # Resolve a user's active profiles into the merged set of:
  #   groups       - system groups to assign
  #   features     - resolved feature cfgs (merged across profiles, later wins)
  #   homeModules  - ordered list of home-manager modules to include
  resolveProfiles = userName: hostUserCfg:
    let
      userDef      = config.nixie.users.${userName};
      # "default" is always first, then user-specified profiles, deduplicated.
      profileNames = lib.unique (
        lib.optional (userDef.profiles ? "default") "default"
        ++ hostUserCfg.profiles
      );
      # Silently skip any profile name that doesn't exist on this user.
      # Validation catches unknown features; unknown profiles are checked separately.
      activeProfiles = map (n: userDef.profiles.${n})
        (lib.filter (n: userDef.profiles ? ${n}) profileNames);
    in {
      groups = lib.unique (
        userDef.groups
        ++ lib.concatMap (p: p.groups) activeProfiles
        ++ hostUserCfg.groups            # host-enrollment-level groups
      );
      # Later profiles override earlier ones for the same feature key.
      features = lib.mapAttrs resolveFeatureCfg
        (lib.foldl' lib.recursiveUpdate {} (map (p: p.features) activeProfiles));
      # Modules in order: profiles (default first), then host user override (last = wins).
      homeModules =
        lib.filter (x: x != null) (map (p: p.home) activeProfiles)
        ++ lib.optional (hostUserCfg.home != null) hostUserCfg.home;
    };

  # ── NixOS module builders ──────────────────────────────────────────────

  # One NixOS module per active host feature.
  # Sets the feature's resolved cfg into config.nixie.features.<name>
  # (options are declared once in baseNixosModule).
  # Then calls the feature's nixos body with cfg injected.
  mkHostFeatureNixosModule = featureName: resolvedCfg: feature:
    { config, pkgs, lib, ... }:
    {
      nixie.features.${featureName} = resolvedCfg;
      imports = lib.optional (feature.nixos != null) (
        # cfg is available lazily — the NixOS module system evaluates this after
        # all config values are merged, so config.nixie.features.<name> is fully resolved.
        feature.nixos {
          cfg = config.nixie.features.${featureName};
          inherit config pkgs lib inputs;
        }
      );
    };

  # Auto-generate users.users.* from declarative identity fields.
  # This covers ~95% of user NixOS needs without any manual nixos module in the user def.
  mkUsersNixosModule = hostCfg:
    { lib, ... }:
    let
      enrolledUsers = enrolledUsersFor hostCfg;
    in {
      users.users = lib.mapAttrs (userName: userDef:
        let
          resolved = resolveProfiles userName hostCfg.users.${userName};
        in
        lib.filterAttrs (_: v: v != null && v != []) {
          uid          = userDef.uid;
          shell        = userDef.shell;
          isNormalUser = true;
          extraGroups  = resolved.groups;
          openssh.authorizedKeys.keys = userDef.sshKeys;
        }
      ) enrolledUsers;
    };

  # ── home-manager integration ──────────────────────────────────────────

  # Build a home-manager module for a feature with a pre-resolved cfg.
  # Used for both host-level features (in sharedModules) and
  # profile features (in per-user imports).
  mkFeatureHomeModule = featureName: resolvedCfg: feature:
    { config, pkgs, lib, ... }:
    feature.home { cfg = resolvedCfg; inherit config pkgs lib inputs; };

  mkHmModule = hostCfg:
    { lib, ... }:
    let
      enrolledUsers = enrolledUsersFor hostCfg;

      # Host feature home modules → sharedModules (all users on this host get them).
      hostFeatHomeModules = lib.concatLists (lib.mapAttrsToList (featureName: rawValues:
        let
          feature     = allFeatures.${featureName};
          resolvedCfg = resolveFeatureCfg featureName rawValues;
        in
        lib.optional (feature.home != null)
          (mkFeatureHomeModule featureName resolvedCfg feature)
      ) hostCfg.features);

      # Per-user home configs: profile feature homes + profile inline homes + host user override.
      userHomeImports = lib.mapAttrs (userName: _:
        let
          resolved = resolveProfiles userName hostCfg.users.${userName};

          profileFeatHomeModules = lib.concatLists (lib.mapAttrsToList (featureName: resolvedCfg:
            let feature = allFeatures.${featureName};
            in lib.optional (feature.home != null)
              (mkFeatureHomeModule featureName resolvedCfg feature)
          ) resolved.features);
        in
        profileFeatHomeModules ++ resolved.homeModules
      ) enrolledUsers;
    in {
      imports = [ inputs.home-manager.nixosModules.home-manager ];
      home-manager = {
        useGlobalPkgs    = true;
        useUserPackages  = true;
        extraSpecialArgs = { inherit inputs; };
        sharedModules    =
          hostFeatHomeModules
          ++ lib.optional (hostCfg.home != null) hostCfg.home;
        users = lib.mapAttrs (_: imports:
          lib.mkIf (imports != []) { inherit imports; }
        ) userHomeImports;
      };
    };

  # ── Validation ────────────────────────────────────────────────────────

  mkValidationModule = hostName: hostCfg:
    let
      knownFeatureNames = lib.attrNames allFeatures;
      enrolledUsers     = enrolledUsersFor hostCfg;

      checkFeatureNames = origin: names:
        map (n: {
          assertion = lib.elem n knownFeatureNames;
          message   = ''
            ${origin}: unknown feature "${n}".
            Known features: ${lib.concatStringsSep ", " knownFeatureNames}
          '';
        }) names;

      checkUserNames = origin: names:
        map (n: {
          assertion = config.nixie.users ? ${n};
          message   = "${origin}: unknown user \"${n}\".";
        }) names;

      checkProfileNames = userName: hostUserCfg:
        let
          userProfiles = if config.nixie.users ? ${userName}
            then config.nixie.users.${userName}.profiles
            else {};
        in
        map (profileName: {
          assertion = userProfiles ? ${profileName};
          message = ''
            hosts.${hostName}.users.${userName}.profiles: unknown profile "${profileName}".
            Known profiles: ${lib.concatStringsSep ", " (lib.attrNames userProfiles)}
          '';
        }) hostUserCfg.profiles;
    in
    { ... }: {
      assertions =
        # Host feature names
        checkFeatureNames "hosts.${hostName}.features" (lib.attrNames hostCfg.features)
        # Enrolled user names
        ++ checkUserNames "hosts.${hostName}.users" (lib.attrNames hostCfg.users)
        # Host user profile names
        ++ lib.concatLists (lib.mapAttrsToList checkProfileNames hostCfg.users)
        # Profile feature names (for each enrolled user's profiles)
        ++ lib.concatLists (lib.mapAttrsToList (userName: userDef:
          lib.concatLists (lib.mapAttrsToList (profileName: profile:
            checkFeatureNames
              "users.${userName}.profiles.${profileName}.features"
              (lib.attrNames profile.features)
          ) userDef.profiles)
        ) enrolledUsers);
    };

  # ── Host system builder ───────────────────────────────────────────────

  mkHostSystem = hostName: hostCfg:
    let
      enrolledUsers = enrolledUsersFor hostCfg;
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit (hostCfg) system;
      specialArgs = { inherit inputs lib; };
      modules =
        # 1. Base module — declares options.nixie namespace and accumulation points.
        #    Must be first so all other modules can freely write to config.nixie.*.
        [ baseNixosModule ]

        # 2. Feature NixOS modules — one per active host feature.
        ++ lib.mapAttrsToList (featureName: rawValues:
          mkHostFeatureNixosModule featureName
            (resolveFeatureCfg featureName rawValues)
            allFeatures.${featureName}
        ) hostCfg.features

        # 3. Auto-generated user accounts from identity fields.
        ++ [ (mkUsersNixosModule hostCfg) ]

        # 4. User nixos escape hatches (rarely used).
        ++ lib.concatLists (lib.mapAttrsToList (_: userDef:
          lib.optional (userDef.nixos != null) userDef.nixos
        ) enrolledUsers)

        # 5. home-manager integration.
        ++ [ (mkHmModule hostCfg) ]

        # 6. Validation — assertions surface unknown names clearly.
        ++ [ (mkValidationModule hostName hostCfg) ]

        # 7. Host nixos config — highest priority, applied last.
        ++ lib.optional (hostCfg.nixos != null) hostCfg.nixos

        ++ hostCfg.extraModules;
    };

in
{
  options.nixie = mkOption {
    default     = {};
    description = "nixie module registry.";
    type = types.submodule {
      freeformType = types.lazyAttrsOf featureType;
      options = {
        users = mkOption { type = types.attrsOf userType;  default = {}; };
        hosts = mkOption { type = types.attrsOf hostType;  default = {}; };
      };
    };
  };

  config = {
    systems = lib.unique (lib.mapAttrsToList (_: h: h.system) config.nixie.hosts);
    flake.nixosConfigurations = lib.mapAttrs mkHostSystem config.nixie.hosts;
  };
}
