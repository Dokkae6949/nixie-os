{ ... }:

{
  nixie.time = {
    description = "time server configuration";

    nixos = { inputs, pkgs, ... }: {
      networking.timeServers = [
        "pool.ntp.org"
        "time.cloudflare.com"
        "time.google.com"
      ];
    };
  };
}
