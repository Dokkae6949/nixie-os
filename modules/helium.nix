{ inputs, ... }:

{
  nixie.helium = {
    description = "lightweight chromium browser";

    home = { ... }: {
      home.packages = [
        inputs.helium.packages.${system}.default
      ];
    };
  };
}
