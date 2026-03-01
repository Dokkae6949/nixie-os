{ lib, ... }:

{
  nixie.persist = {
    options = {
      enable = lib.mkEnableOption "impermanence (ephemeral root)";

      # Other modules append to these lists to persist their own paths.
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

    nixos = { config, lib, inputs, ... }: {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      environment.persistence."/.persist" = lib.mkIf config.nixie.persist.enable {
        hideMounts = true;

        directories =
          [ "/etc/nixos"
            "/etc/NetworkManager/system-connections"
            "/var/lib/nixos"
          ] ++ config.nixie.persist.directories;

        files =
          [ "/etc/machine-id"
          ] ++ config.nixie.persist.files;
      };

      fileSystems."/.persist".neededForBoot =
        lib.mkIf config.nixie.persist.enable (lib.mkDefault true);
    };
  };
}
