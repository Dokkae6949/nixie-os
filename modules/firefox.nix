{ ... }:

{
  nixie.firefox= {
    description = "firefox browser";

    nixos = { ... }: { };

    home = { ... }: {
      programs.firefox = {
        enable = true;
      };
    };
  };
}
