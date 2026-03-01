# The dendritic library — a flake-parts module providing the `nixie` namespace.
#
# Feature API (same as before — user is happy with this):
#   nixie.<name> = {
#     options = { ... };   # NixOS option declarations, globally available in all configs
#     nixos   = { ... };   # NixOS module, applied when nixie.<name>.enable = true
#     home    = { ... };   # home-manager module, added to sharedModules for all users
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
      options = mkOption {
        type    = types.anything;
        default = { };
        description = "NixOS option declarations placed under options.nixie.<name>.";
      };
      nixos = mkOption {
        type    = types.nullOr types.raw;
        default = null;
        description = "NixOS module for this feature.";
      };
      home = mkOption {
        type    = types.nullOr types.raw;
        default = null;
        description = "home-manager module added to sharedModules for all users.";
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

  # Build a NixOS module that declares options.nixie.<name> for each feature with options.
  mkGlobalOptionsModule = features:
    let withOptions = lib.filterAttrs (_: f: f.options != { }) features;
    in { lib, ... }: {
      options.nixie = lib.mapAttrs (_: f: f.options) withOptions;
    };

  mkNixosModules = features:
    lib.concatLists (lib.mapAttrsToList (_: f:
      lib.optional (f.nixos != null) f.nixos
    ) features);

  mkHomeModules = features:
    lib.concatLists (lib.mapAttrsToList (_: f:
      lib.optional (f.home != null) f.home
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
    # freeformType lets nixie.<name> = { options, nixos, home } work for features,
    # while 'users' and 'hosts' are declared as first-class typed sub-options.
    type = types.submodule {
      freeformType = types.attrsOf featureType;
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

