# The dendritic library — a flake-parts module providing the `nixie` namespace.
#
# Inspired by vic/den and vic/flake-aspects: features are plain modules, activated
# by listing them in the host's `features` field. No per-feature enable options,
# no lib.mkIf gating, no separate nixosImports/homeImports needed.
#
# Feature API:
#   nixie.<name> = {
#     description = "short description";  # documentation only
#     options     = { ... };              # extra NixOS option declarations under options.nixie.<name>
#     nixos       = { config, pkgs, ... }: {
#       imports = [ ... ];                # unconditional — just works, no special handling needed
#       services.foo.enable = true;       # body is included as-is when the feature is active
#     };
#     home        = { pkgs, ... }: { ... };  # home-manager module, applied via sharedModules
#   };
#
# User API:
#   nixie.users.<name> = {
#     nixos = { ... };  # NixOS module for this user (use lib.mkDefault for host-overridable values)
#     home  = { ... };  # home-manager module for this user
#   };
#
# Host API:
#   nixie.hosts.<name> = {
#     system       = "x86_64-linux";
#     features     = [ "battery" "network" "persist" ];  # activates listed feature modules
#     users        = [ "alice" "bob" ];  # enrolled users
#     nixos        = { ... };            # host NixOS module (takes priority over user nixos)
#     home         = { ... };            # home defaults for all users (use lib.mkDefault)
#     extraModules = [ ... ];            # additional NixOS modules
#   };
#
# Hosts are automatically added to flake.nixosConfigurations.
# Systems are automatically derived from the union of all host.system values.
{ lib, config, inputs, ... }:

let
  inherit (lib) mkOption types;

  # ── Types ────────────────────────────────────────────────────────────────

  # Feature type — plain module containers, activated by listing in host.features.
  # Inspired by den/flake-aspects: no enable options, no gating, imports just work.
  featureType = types.submodule {
    options = {
      description = mkOption {
        type    = types.nullOr types.str;
        default = null;
        description = "Short feature description (documentation only).";
      };
      options = mkOption {
        type    = types.anything;
        default = { };
        description = "Extra NixOS option declarations placed under options.nixie.<name>.";
      };
      nixos = mkOption {
        type    = types.nullOr types.raw;
        default = null;
        description = ''
          NixOS module for this feature. Included as-is when the feature is listed in
          host.features — no conditional gating. imports inside the body work naturally.
        '';
      };
      home = mkOption {
        type    = types.nullOr types.raw;
        default = null;
        description = ''
          home-manager module for this feature. Added to sharedModules when the feature is
          listed in host.features — no conditional gating.
        '';
      };
    };
  };

  # User type — nixos is treated as defaults (use lib.mkDefault), home is user-specific.
  userType = types.submodule {
    options = {
      nixos = mkOption {
        type    = types.nullOr types.raw;
        default = null;
        description = ''
          NixOS module for this user (user account, system config).
          Use lib.mkDefault for values you want the host to be able to override.
        '';
      };
      home = mkOption {
        type    = types.nullOr types.raw;
        default = null;
        description = "home-manager module for this user (applied via home-manager.users.<name>).";
      };
    };
  };

  # Host type — nixos is authoritative, home is applied as defaults to all users.
  hostType = types.submodule {
    options = {
      system = mkOption {
        type    = types.str;
        default = "x86_64-linux";
        description = "Target system architecture.";
      };
      features = mkOption {
        type    = types.listOf types.str;
        default = [ ];
        description = ''
          Feature names (from nixie.<name>) to activate on this host.
          Only listed features have their nixos/home modules included in the system.
          Inspired by den/flake-aspects: activation via inclusion, not per-feature enable options.
        '';
      };
      users = mkOption {
        type    = types.listOf types.str;
        default = [ ];
        description = "User names (from nixie.users) to include in this host.";
      };
      nixos = mkOption {
        type    = types.nullOr types.raw;
        default = null;
        description = "Host-specific NixOS module (takes priority over user nixos defaults).";
      };
      home = mkOption {
        type    = types.nullOr types.raw;
        default = null;
        description = ''
          Default home-manager module applied to all users on this host (via sharedModules).
          Use lib.mkDefault for values that users should be able to override.
        '';
      };
      extraModules = mkOption {
        type    = types.listOf types.raw;
        default = [ ];
        description = "Additional NixOS modules to include.";
      };
    };
  };

  # ── Helpers ──────────────────────────────────────────────────────────────

  # Extract only feature entries — exclude the reserved 'users' and 'hosts' keys.
  getFeatures = nixie:
    lib.filterAttrs (n: _: !lib.elem n [ "users" "hosts" ]) nixie;

  # Filter features to only those activated by the host's features list.
  getActiveFeatures = hostCfg: features:
    lib.filterAttrs (n: _: lib.elem n hostCfg.features) features;

  # Build a NixOS module that declares options.nixie.<name> for features with extra options.
  # No enable option is auto-generated — the den-inspired approach uses the features list instead.
  mkGlobalOptionsModule = features:
    let withOpts = lib.filterAttrs (_: f: f.options != { }) features;
    in if withOpts == {} then {}
       else { lib, ... }: {
         options.nixie = lib.mapAttrs (_: f: f.options) withOpts;
       };

  # Collect NixOS modules for active features — no gating, modules included as-is.
  mkNixosModules = activeFeatures:
    lib.concatLists (lib.mapAttrsToList (_: f:
      lib.optional (f.nixos != null) f.nixos
    ) activeFeatures);

  # Collect home-manager sharedModules for active features — no gating, included as-is.
  mkHomeModules = activeFeatures:
    lib.concatLists (lib.mapAttrsToList (_: f:
      lib.optional (f.home != null) f.home
    ) activeFeatures);

  # Build a nixosSystem for one host entry.
  mkHostSystem = _hostName: hostCfg:
    let
      features       = getFeatures config.nixie;
      activeFeatures = getActiveFeatures hostCfg features;
      allUsers       = config.nixie.users;
      hostUsers      = lib.filterAttrs (n: _: lib.elem n hostCfg.users) allUsers;

      globalOpts = mkGlobalOptionsModule features;
      featNixos  = mkNixosModules activeFeatures;
      featHome   = mkHomeModules activeFeatures;

      # User NixOS modules — included before the host nixos module so that
      # host settings naturally take priority (later modules win on conflicts).
      # Convention: users use lib.mkDefault for host-overridable values.
      userNixos = lib.concatLists (lib.mapAttrsToList (_: u:
        lib.optional (u.nixos != null) u.nixos
      ) hostUsers);

      # Per-user home-manager configs (wired to home-manager.users.<name>).
      userHomes = lib.filterAttrs (_: u: u.home != null) hostUsers;

      hmModule = { lib, ... }: {
        imports = [ inputs.home-manager.nixosModules.home-manager ];
        home-manager = {
          useGlobalPkgs    = true;
          useUserPackages  = true;
          extraSpecialArgs = { inherit inputs; };
          # Feature home modules + host-level home defaults (host should use mkDefault).
          sharedModules =
            featHome
            ++ lib.optional (hostCfg.home != null) hostCfg.home;
          # Per-user home configs take full priority over sharedModules.
          users = lib.mapAttrs (_: u: u.home) userHomes;
        };
      };
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit (hostCfg) system;
      specialArgs = { inherit inputs lib; };
      modules =
        lib.optional (globalOpts != {}) globalOpts
        ++ [ hmModule ]
        ++ featNixos
        ++ userNixos                                              # user nixos (defaults)
        ++ lib.optional (hostCfg.nixos != null) hostCfg.nixos    # host nixos (authoritative)
        ++ hostCfg.extraModules;
    };

in
{
  # ── Options ──────────────────────────────────────────────────────────────

  options.nixie = mkOption {
    default     = { };
    description = "Dendritic module registry.";
    # lazyAttrsOf avoids the deprecated functor.wrapped access path that
    # types.attrsOf triggers in the module system, eliminating the evaluation
    # warnings. Semantics are identical for submodule element types.
    type = types.submodule {
      freeformType = types.lazyAttrsOf featureType;
      options = {
        users = mkOption {
          type    = types.attrsOf userType;
          default = { };
          description = "User definitions. Users can also enroll themselves into hosts.";
        };
        hosts = mkOption {
          type    = types.attrsOf hostType;
          default = { };
          description = "Host definitions. Each host auto-generates a nixosConfiguration.";
        };
      };
    };
  };

  # ── Auto-wire hosts into flake outputs ───────────────────────────────────

  config = {
    # Derive supported systems from the union of all host.system values.
    systems = lib.unique (
      lib.mapAttrsToList (_: h: h.system) config.nixie.hosts
    );

    # Build one nixosConfiguration per host.
    flake.nixosConfigurations = lib.mapAttrs mkHostSystem config.nixie.hosts;
  };
}

