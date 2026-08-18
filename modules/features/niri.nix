{ inputs, ... }:

{
  flake.modules.nixos.niri = { pkgs, ... }: {
    nixpkgs.overlays = [ inputs.niri.overlays.niri ];

    nix.settings = {
      substituters = [ "https://niri.cachix.org" ];
      trusted-public-keys = [
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];
    };

    programs.niri = {
      enable = true;
      package = pkgs.niri;
    };

    environment.systemPackages = with pkgs; [
      alacritty
      brightnessctl
      cliphist
      playerctl
      rofi
      waybar
      wl-clipboard
    ];

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };
  };

  flake.modules.homeManager.niri = { pkgs, ... }: {
    home.pointerCursor = {
      enable = true;
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };
  };
}
