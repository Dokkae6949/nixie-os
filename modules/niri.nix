{ ... }:

{
  nixie.niri = {
    description = "niri Wayland compositor";

    nixos = { inputs, pkgs, ... }: {
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
