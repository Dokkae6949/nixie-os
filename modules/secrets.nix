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

    nixos = { ... }: {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = sopsConfig;

      # Persist the sops age key across ephemeral reboots.
      nixie.persist.directories = [ "/var/lib/sops" ];
    };

    home = { pkgs, ... }: {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      sops = sopsConfig;

      home.packages = [ pkgs.sops ];
    };
  };
}
