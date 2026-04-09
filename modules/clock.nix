{ ... }:

{
  nixie.clock= {
    description = "time sync configuration";

    nixos = { ... }: {
      services.automatic-timezoned.enable = true;
    };
  };
}
