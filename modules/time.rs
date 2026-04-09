{ ... }:

{
  nixie.time = {
    description = "time server configuration";

    nixos = { inputs, pkgs, ... }: {
      services.timesyncd.enable = true;
      services.localtimed.enable = true;
      services.geoclue2.enable = true;
    };
  };
}
