{ config, ... }:

{
  flake.modules.nixos.desktop.imports = with config.flake.modules.nixos; [
    keyboard
    niri
    unfree
  ];

  flake.modules.homeManager.desktop.imports = with config.flake.modules.homeManager; [
    discord
    email
    firefox
    fonts
    helium
    niri
    quickshell
    spotify
  ];
}
