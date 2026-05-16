{ lib, inputs, ... }:

{
  nixie.persist = {
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

    nixos = { cfg, config, lib, ... }: {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      options.nixie.persist = {
        directories = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
        };
        files = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
        };
      };

      config = {
        nixie.persist.directories = cfg.directories;
        nixie.persist.files = cfg.files;

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
  };
}
