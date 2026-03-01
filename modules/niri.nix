{ lib, ... }:

{
  nixie.niri = {
    options = {
      enable = lib.mkEnableOption "niri Wayland compositor";
    };

    nixos = { config, lib, inputs, pkgs, ... }: lib.mkIf config.nixie.niri.enable {
      nixpkgs.overlays = [ inputs.niri.overlays.niri ];

      programs.niri = {
        enable = true;
        package = pkgs.niri-unstable;
      };

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
      };
    };
  };
}
