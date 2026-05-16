{ ... }:

{
  nixie.discord = {
    home = { pkgs, ... }: {
      programs.vesktop = {
        enable = true;
      };
    };
  };
}
