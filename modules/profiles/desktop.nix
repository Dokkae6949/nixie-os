{ config, ... }:

{
  flake.modules.nixos.desktop.imports = with config.flake.modules.nixos; [
    gnome-keyring
    keyboard
    niri
    unfree
  ];

  flake.modules.homeManager.desktop.imports = with config.flake.modules.homeManager; [
    discord
    matrix
    email
    firefox
    fonts
    helium
    niri
    quickshell
    spotify
  ];
}
