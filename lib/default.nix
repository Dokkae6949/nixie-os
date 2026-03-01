# The dendritic library — a flake-parts module that provides the `nixie` namespace.
#
# Every feature is registered as:
#
#   nixie.<name> = {
#     options = { ... };   # NixOS option declarations, globally available in all configs
#     nixos   = { ... };   # NixOS module function, applied when nixie.<name>.enable = true
#     home    = { ... };   # home-manager module, added to sharedModules for all users
#   };
#
# Hosts build their configuration with `dendritic.mkSystem`.
{ lib, config, inputs, ... }:

let
  inherit (lib) mkOption types;

  # Sub-module type describing one nixie feature entry.
  featureType = types.submodule {
    options = {
      options = mkOption {
        type    = types.anything;
        default = { };
        description = "NixOS option declarations placed under options.nixie.<name>.";
      };
      nixos = mkOption {
        # types.raw: stored as-is, no merging — correct for NixOS module functions.
        type    = types.nullOr types.raw;
        default = null;
        description = "NixOS module applied when nixie.<name>.enable is true.";
      };
      home = mkOption {
        type    = types.nullOr types.raw;
        default = null;
        description = "home-manager module added to home-manager.sharedModules.";
      };
    };
  };

  # Build a NixOS module that declares every registered feature's options under
  # options.nixie.<name> so they are globally available in all configurations.
  # Features with no options (options = {}) are skipped to avoid empty namespaces.
  mkGlobalOptionsModule = features:
    let
      withOptions = lib.filterAttrs (_: feat: feat.options != { }) features;
    in
    { lib, ... }:
    {
      options.nixie = lib.mapAttrs (_: feat: feat.options) withOptions;
    };

  # Collect NixOS modules from every registered feature that has a `nixos` key.
  mkNixosModules = features:
    lib.concatLists (lib.mapAttrsToList (_: feat:
      lib.optional (feat.nixos != null) feat.nixos
    ) features);

  # Collect home-manager modules from every registered feature that has a `home` key.
  mkHomeModules = features:
    lib.concatLists (lib.mapAttrsToList (_: feat:
      lib.optional (feat.home != null) feat.home
    ) features);

in
{
  # ── Flake-parts option: the registry of nixie features ──────────────────────
  options.nixie = mkOption {
    type        = types.attrsOf featureType;
    default     = { };
    description = "Registry of dendritic feature modules.";
  };

  # ── Expose `dendritic` as a flake-parts module argument ─────────────────────
  config._module.args.dendritic = {

    # Build a nixosConfiguration from all registered nixie features.
    #
    #   dendritic.mkSystem {
    #     system       = "x86_64-linux";
    #     extraModules = [ inputs.disko.nixosModules.disko ./_config { ... } ];
    #   }
    mkSystem =
      { system
      , extraModules ? [ ]
      }:
      let
        features = config.nixie;

        globalOptionsModule = mkGlobalOptionsModule features;
        nixosModules        = mkNixosModules features;
        homeModules         = mkHomeModules features;

        hmIntegrationModule = { lib, ... }: {
          imports = [ inputs.home-manager.nixosModules.home-manager ];
          home-manager = {
            useGlobalPkgs   = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs lib; };
            sharedModules   = homeModules;
          };
        };
      in
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs lib; };
        modules =
          [ globalOptionsModule hmIntegrationModule ]
          ++ nixosModules
          ++ extraModules;
      };
  };
}
