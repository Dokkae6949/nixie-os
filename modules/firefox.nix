{ ... }:

{
  nixie.firefox= {
    nixos = { ... }: { };

    home = { ... }: {
      programs.firefox = {
        enable = true;
      };
    };
  };
}
