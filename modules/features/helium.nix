{ inputs, ... }:

{
  flake.modules.homeManager.helium = { pkgs, ... }: {
    home.packages = [
      inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
