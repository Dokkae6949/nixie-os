{ lib, ... }:

{
  nixie.keyboard = {
    options = {
      enable = lib.mkEnableOption "keyboard remapping (keyd)";
    };

    nixos = { config, lib, ... }: lib.mkIf config.nixie.keyboard.enable {
      console.useXkbConfig = true;

      services = {
        xserver.xkb.layout = "at";

        keyd = {
          enable = true;

          keyboards.default = {
            ids = [ "*" ];
            settings = {
              # Overload capslock to control when held, escape when tapped.
              main = {
                capslock = "overload(control, escape)";
                esc = "capslock";
                kpenter = "enter";
              };
            };
          };
        };
      };
    };
  };
}
