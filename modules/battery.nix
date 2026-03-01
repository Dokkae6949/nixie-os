{ ... }:

{
  nixie.battery = {
    description = "battery management (upower)";

    nixos = { ... }: {
      services.upower.enable = true;
    };
  };
}
