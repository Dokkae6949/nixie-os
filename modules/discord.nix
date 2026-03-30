{ ... }:

{
  nixie.discord = {
    description = "alternative discord client called vesktop";

    home = { pkgs, ... }: {
      programs.vesktop = {
        enable = true;
      };
    };
  };
}
