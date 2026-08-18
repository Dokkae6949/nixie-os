{ inputs, lib, ... }:

{
  flake.modules.nixos.nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    nix = {
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        flake-registry = "";
        trusted-users = [ "root" "@wheel" ];
      };

      channel.enable = false;
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (name: _: "${name}=flake:${name}") flakeInputs;
    };
  };
}
