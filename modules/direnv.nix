{ ... }:

{
  nixie.direnv = {
    description = "shell environment loading tool direnv";

    home = { ... }: {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };
  };
}
