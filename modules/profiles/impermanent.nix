{ config, ... }:

{
  flake.modules.nixos.impermanent.imports = with config.flake.modules.nixos; [
    persistence
    networkPersistence
    secretsPersistence
  ];
}
