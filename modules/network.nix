{ lib, ... }:

{
  nixie.network = {
    options = {
      enable = lib.mkEnableOption "NetworkManager networking";
    };

    nixos = { config, lib, ... }: lib.mkIf config.nixie.network.enable {
      networking.networkmanager.enable = true;

      nixie.persist.directories = [ "/etc/NetworkManager/system-connections" ];
    };
  };
}
