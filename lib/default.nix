# The dendritic library — a flake-parts module providing the `nixie` namespace.
#
# Feature API:
#   nixie.<name> = {
#     description    = "short description";   # library auto-generates `enable` and auto-gates bodies
#     options        = { ... };               # extra NixOS option declarations under options.nixie.<name>
#     nixosImports   = [ ... ];               # NixOS modules always imported unconditionally
#     nixos          = { ... };               # NixOS body — auto-gated by enable when description is set
#     homeImports    = [ ... ];               # home-manager modules always imported unconditionally
#     home           = { ... };               # home body — auto-gated by enable when description is set
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
#     users        = [ "alice" "bob" ];   # enrolled users (or users enroll themselves)
#     nixos        = { ... };             # host NixOS module (takes priority over user nixos)
#     home         = { ... };             # home defaults for all users (use lib.mkDefault)
#     extraModules = [ ... ];             # additional NixOS modules
#   };
#
# Hosts are automatically added to flake.nixosConfigurations.
# Systems are automatically derived from the union of all host.system values.
{ lib, config, inputs, ... }:

let
  inherit (lib) mkOption types;

  # ── Types ────────────────────────────────────────────────────────────────

  # Feature/module type — unchanged from before.
  featureType = types.submodule {
    options = {
      description = mkOption {
        type    = types.nullOr types.str;
        default = null;
        description = ''
          Short feature description. When set, the library automatically:
          1. Generates `enable = lib.mkEnableOption description` under options.nixie.<name>.
          2. Gates the nixos body with `lib.mkIf config.nixie.<name>.enable`.
          3. Gates the home body with `lib.mkIf (osConfig.nixie.<name>.enable or false)`.
        '';
      };
      options = mkOption {
        type    = types.anything;
        default = { };
        description = "Additional NixOS option declarations placed under options.nixie.<name>.";
      };
      nixosImports = mkOption {
        type    = types.listOf types.raw;
        default = [ ];
        description = ''
          NixOS modules always imported unconditionally (e.g. external modules that declare
          options required by the nixos body). The library lifts these out so the nixos body
          can freely use lib.mkIf without worrying about the "imports must be unconditional" rule.
        '';
      };
      nixos = mkOption {
        type    = types.nullOr types.raw;
        default = null;
        description = "NixOS module body. Auto-gated by enable when description is set.";
      };
      homeImports = mkOption {
        type    = types.listOf types.raw;
        default = [ ];
        description = ''
          home-manager modules always imported unconditionally into sharedModules.
          Same idea as nixosImports but for home-manager.
        '';
      };
      home = mkOption {
        type    = types.nullOr types.raw;
        default = null;
        description = "home-manager module body. Auto-gated by enable when description is set.";
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

  # Build a NixOS module that declares options.nixie.<name> for each feature.
  # When description is set the library auto-generates `enable = lib.mkEnableOption description`.
  mkGlobalOptionsModule = features:
    let withOpts = lib.filterAttrs (_: f: f.options != { } || f.description != null) features;
    in { lib, ... }: {
      options.nixie = lib.mapAttrs (_: f:
        (lib.optionalAttrs (f.description != null) { enable = lib.mkEnableOption f.description; })
        // f.options
      ) withOpts;
    };

  mkNixosModules = features:
    let
      # Collect all nixosImports into one unconditional module so feature bodies
      # can freely use lib.mkIf without worrying about imports ordering.
      allNixosImports = lib.concatLists (lib.mapAttrsToList (_: f: f.nixosImports) features);
      importsModule   = lib.optional (allNixosImports != []) { imports = allNixosImports; };
      # When description is set, wrap the nixos body with the enable guard automatically
      # so feature authors don't need to write lib.mkIf config.nixie.<name>.enable manually.
      autoGate = name: f: mod:
        if f.description == null then mod
        else args@{ config, lib, ... }:
          lib.mkIf config.nixie.${name}.enable (
            if lib.isFunction mod then mod args else mod
          );
    in
    importsModule
    ++ lib.concatLists (lib.mapAttrsToList (name: f:
      lib.optional (f.nixos != null) (autoGate name f f.nixos)
    ) features);

  mkHomeModules = features:
    let
      # Same pattern for homeImports — lifted into one unconditional sharedModule.
      allHomeImports = lib.concatLists (lib.mapAttrsToList (_: f: f.homeImports) features);
      importsModule  = lib.optional (allHomeImports != []) { imports = allHomeImports; };
      # When description is set, wrap the home body with the enable guard automatically.
      # Uses `or false` to gracefully handle cases where the NixOS option doesn't exist.
      autoGate = name: f: mod:
        if f.description == null then mod
        else args@{ osConfig, lib, ... }:
          lib.mkIf (osConfig.nixie.${name}.enable or false) (
            if lib.isFunction mod then mod args else mod
          );
    in
    importsModule
    ++ lib.concatLists (lib.mapAttrsToList (name: f:
      lib.optional (f.home != null) (autoGate name f f.home)
    ) features);

  # Build a nixosSystem for one host entry.
  mkHostSystem = _hostName: hostCfg:
    let
      features  = getFeatures config.nixie;
      allUsers  = config.nixie.users;
      hostUsers = lib.filterAttrs (n: _: lib.elem n hostCfg.users) allUsers;

      globalOpts = mkGlobalOptionsModule features;
      featNixos  = mkNixosModules features;
      featHome   = mkHomeModules features;

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
        [ globalOpts hmModule ]
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

