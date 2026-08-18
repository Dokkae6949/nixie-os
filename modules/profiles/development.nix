{ config, ... }:

{
  flake.modules.nixos.development.imports = with config.flake.modules.nixos; [
    docker
    nix-ld
    postgresql
  ];

  flake.modules.homeManager.development.imports = with config.flake.modules.homeManager; [
    direnv
    helix
    secrets
  ];
}
