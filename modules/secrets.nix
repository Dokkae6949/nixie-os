{ inputs, ... }:
let
  sops_config = {
    defaultSopsFile = ../secrets/default.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops/age/keys.txt";
  };
in
{
  nixi.secrets = {
    nixos = {
      imports = [ inputs.sops-nix.nixosModules.sops ];
      sops = sops_config;
    };

    homeManager = { pkgs, ... }: {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];
      sops = sops_config;

      home.packages = [ pkgs.sops ];
    };
  };
}
