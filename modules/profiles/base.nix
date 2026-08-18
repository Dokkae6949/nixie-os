{ config, ... }:

{
  flake.modules.nixos.base.imports = with config.flake.modules.nixos; [
    clock
    network
    nix
    secrets
    shell
    sudo
  ];

  flake.modules.homeManager.base.imports = with config.flake.modules.homeManager; [
    cliTools
    shell
  ];
}
