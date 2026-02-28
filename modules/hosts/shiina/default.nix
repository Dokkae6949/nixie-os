{ inputs, lib, den, __findFile, ... }:

{
  # Supported system architectures.
  systems = [ "x86_64-linux" ];

  den.hosts.x86_64-linux.shiina = { };

  den.aspects.shiina = {
    includes = [
      <nixi/network>
      <nixi/battery>

      <nixi/niri>
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

      nix = let
        flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
      in {
        settings = {
          # Enable flakes and new 'nix' command
          experimental-features = "nix-command flakes";

          # Opinionated: disable global registry
          flake-registry = "";

          trusted-users = ["root" "@wheel"];
        };

        # Opinionated: disable channels
        channel.enable = false;

        # Opinionated: make flake registry and nix path match flake inputs
        registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
        nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
      };

      system.stateVersion = "25.11";
    };

    homeManager = { ... }: {
      home.stateVersion = "25.11";
    };
  };
}
