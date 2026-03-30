{ ... }:

{
  nixie.spotify = {
    description = "music listening service client application";

    home = { pkgs, ... }: {
      programs.spotify = {
        enable = true;
      };
    };
  };
}
