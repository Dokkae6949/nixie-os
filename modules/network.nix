{ ... }:

{
  nixie.network = {
    description = "NetworkManager networking";

    nixos = { ... }: {
      networking.networkmanager = {
        enable = true;
        dns = "systemd-resolved";
      };

      services.resolved = {
        enable = true;
      };

      nixie.persist.directories = [ "/etc/NetworkManager/system-connections" ];
    };
  };
}
