{ ... }:

{
  nixie.bluetooth= {
    nixos = { ... }: {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
    };
  };
}
