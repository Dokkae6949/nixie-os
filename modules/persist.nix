{ lib, inputs, ... }:

{
  nixie.persist = {
    description = "impermanence (ephemeral root)";

    options = {
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

    nixos = { config, lib, ... }: {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

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
