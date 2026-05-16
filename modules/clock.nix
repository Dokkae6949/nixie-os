{ ... }:

{
  nixie.clock = {
    nixos = { ... }: {
      services.automatic-timezoned.enable = true;
    };
  };
}
