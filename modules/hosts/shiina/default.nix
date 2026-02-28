{ inputs, lib, den, __findFile, ... }:

{
  # Supported system architectures.
  systems = [ "x86_64-linux" ];

  den.hosts.x86_64-linux.shiina = { };

  den.aspects.shiina = {
    includes = [
      <nixi/network>
      <nixi/battery>

      <nixi/secrets>
      <nixi/persist>
      <nixi/keyboard>
    ];

    nixos = { config, ... }: {
      imports = [
        inputs.disko.nixosModules.disko

        ./_config
      ];

      sops.secrets."hosts/shiina/ssh/host_ed25519_key" = {
        sopsFile = ../../../secrets/hosts/shiina.yaml;
      };

      services.openssh.hostKeys = [
        { path = config.sops.secrets."hosts/shiina/ssh/host_ed25519_key".path;
          type = "ed25519";
        }
      ];

      system.stateVersion = "25.05";
    };
  };
}
