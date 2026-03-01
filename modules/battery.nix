{ lib, ... }:

{
  nixie.battery = {
    options = {
      enable = lib.mkEnableOption "battery management (upower)";
    };

    nixos = { config, lib, ... }: lib.mkIf config.nixie.battery.enable {
      services.upower.enable = true;
    };
  };
}
