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

    nixos = { config, lib, inputs, ... }: lib.mkIf config.nixie.secrets.enable {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = sopsConfig;

      # Persist the sops age key across ephemeral reboots.
      nixie.persist.directories = [ "/var/lib/sops" ];
    };

    home = { osConfig, lib, inputs, pkgs, ... }:
      lib.mkIf (osConfig.nixie.secrets.enable or false) {
        imports = [ inputs.sops-nix.homeManagerModules.sops ];

        sops = sopsConfig;

        home.packages = [ pkgs.sops ];
      };
  };
}
