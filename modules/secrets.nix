{ lib, ... }:

let
  sopsConfig = {
    defaultSopsFile   = ../secrets/default.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile       = "/var/lib/sops/age/keys.txt";
  };
in
{
  nixie.secrets = {
    options = {
      enable = lib.mkEnableOption "sops-nix secret management";
    };

    nixos = { config, lib, inputs, ... }: {
      # imports must be unconditional (same reason as persist.nix — options from
      # sops-nix must be declared even when the feature is disabled).
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = lib.mkIf config.nixie.secrets.enable sopsConfig;

      # Persist the sops age key across ephemeral reboots.
      nixie.persist.directories =
        lib.mkIf config.nixie.secrets.enable [ "/var/lib/sops" ];
    };

    home = { osConfig, lib, inputs, pkgs, ... }: {
      # imports must be unconditional — options from sops-nix must be declared
      # even when the feature is disabled, otherwise home-manager's module system
      # tries to set `home-manager.users.<name>.imports` as a NixOS option path.
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      sops = lib.mkIf (osConfig.nixie.secrets.enable or false) sopsConfig;

      home.packages = lib.mkIf (osConfig.nixie.secrets.enable or false) [ pkgs.sops ];
    };
  };
}
