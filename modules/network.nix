{ ... }:

{
  nixie.network = {
    description = "NetworkManager networking";

    nixos = { ... }: {
      networking.networkmanager.enable = true;

      nixie.persist.directories = [ "/etc/NetworkManager/system-connections" ];
    };
  };
}
