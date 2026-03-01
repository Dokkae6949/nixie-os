{ lib, inputs, ... }:

{
  nixie.persist = {
    options = {
      enable = lib.mkEnableOption "impermanence (ephemeral root)";

      directories = lib.mkOption {
        type        = lib.types.listOf lib.types.str;
        default     = [ ];
        description = "Extra directories to persist across reboots.";
      };

      files = lib.mkOption {
        type        = lib.types.listOf lib.types.str;
        default     = [ ];
        description = "Extra files to persist across reboots.";
      };
    };

    nixosImports = [ inputs.impermanence.nixosModules.impermanence ];

    nixos = { config, lib, ... }: lib.mkIf config.nixie.persist.enable {
      fileSystems."/.persist".neededForBoot = lib.mkDefault true;

      environment.persistence."/.persist" = {
        hideMounts = true;

        directories = [
          "/etc/nixos"
          "/var/lib/nixos"
        ] ++ config.nixie.persist.directories;

        files = [
          "/etc/machine-id"
        ] ++ config.nixie.persist.files;
      };
    };
  };
}
