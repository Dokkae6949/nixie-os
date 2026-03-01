{ inputs, lib, ... }:

{
  nixie.hosts.shiina = {
    system = "x86_64-linux";
    users  = [ "kurisu" ];

    nixos = { config, ... }: {
      imports = [
        inputs.disko.nixosModules.disko
        ./_config
      ];

      nixie.battery.enable  = true;
      nixie.keyboard.enable = true;
      nixie.network.enable  = true;
      nixie.niri.enable     = true;
      nixie.persist.enable  = true;
      nixie.secrets.enable  = true;

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
          flake-registry          = "";
          trusted-users           = [ "root" "@wheel" ];
        };

        channel.enable = false;

        registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
        nixPath  = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
      };

      system.stateVersion = "25.11";
    };

    # Home-manager defaults applied to every user on this host.
    # Use lib.mkDefault for any value a user should be able to override.
    home = { lib, ... }: {
      home.stateVersion = lib.mkDefault "25.11";
    };
  };
}
