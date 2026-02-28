{ __findFile, ... }:

{
  # Supported system architectures.
  systems = [ "x86_64-linux" ];

  den.hosts.x86_64-linux.shiina = { };

  den.aspects.shiina = {
    includes = [
      <nixi/secrets>
      <nixi/keyboard>
    ];

    nixos = { ... }: {
      system.stateVersion = "25.05";

      networking.hostName = "shiina";
      networking.networkmanager.enable = true;

      services = {
        upower.enable = true;
      };
    };
  };
}
