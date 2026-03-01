{ lib, inputs, ... }:

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

    nixosImports = [ inputs.sops-nix.nixosModules.sops ];

    nixos = { config, lib, ... }: lib.mkIf config.nixie.secrets.enable {
      sops = sopsConfig;

      # Persist the sops age key across ephemeral reboots.
      nixie.persist.directories = [ "/var/lib/sops" ];
    };

    homeImports = [ inputs.sops-nix.homeManagerModules.sops ];

    home = { osConfig, lib, pkgs, ... }: lib.mkIf (osConfig.nixie.secrets.enable or false) {
      sops = sopsConfig;

      home.packages = [ pkgs.sops ];
    };
  };
}
