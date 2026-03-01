{ inputs, lib, ... }:

{
  nixie.hosts.shiina = {
    system   = "x86_64-linux";
    features = [ "battery" "keyboard" "network" "niri" "persist" "secrets" ];
    users    = [ "kurisu" ];

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
          experimental-features = "nix-command flakes";
          flake-registry = "";
          trusted-users = [ "root" "@wheel" ];
        };

        channel.enable = false;

        registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
        nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
      };

      system.stateVersion = "25.11";
    };

    home = { lib, ... }: {
      home.stateVersion = lib.mkDefault "25.11";
    };
  };
}
