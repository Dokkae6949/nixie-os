{ inputs, ... }:

let
  sopsConfig = {
    defaultSopsFile   = ../secrets/default.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile       = "/var/lib/sops/age/keys.txt";
  };
in
{
  nixie.secrets = {
    description = "sops-nix secret management";

    nixosImports = [ inputs.sops-nix.nixosModules.sops ];

    nixos = { ... }: {
      sops = sopsConfig;

      # Persist the sops age key across ephemeral reboots.
      nixie.persist.directories = [ "/var/lib/sops" ];
    };

    homeImports = [ inputs.sops-nix.homeManagerModules.sops ];

    home = { pkgs, ... }: {
      sops = sopsConfig;

      home.packages = [ pkgs.sops ];
    };
  };
}
