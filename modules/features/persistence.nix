{ inputs, ... }:

{
  flake.modules.nixos.persistence = { lib, ... }: {
    imports = [ inputs.impermanence.nixosModules.impermanence ];

    fileSystems."/.persist".neededForBoot = lib.mkDefault true;

    environment.persistence."/.persist" = {
      hideMounts = true;
      directories = [
        "/etc/nixos"
        "/var/lib/nixos"
      ];
      files = [ "/etc/machine-id" ];
    };
  };
}
