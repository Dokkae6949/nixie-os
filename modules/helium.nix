{ inputs, ... }:

{
  nixie.helium = {
    description = "lightweight chromium browser";

    home = { pkgs, ... }: {
      home.packages = [
        inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
  };
}
