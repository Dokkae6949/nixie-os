{ inputs, ... }:

{
  flake.modules.nixos.secrets = {
    imports = [ inputs.sops-nix.nixosModules.sops ];
  };

  flake.modules.nixos.secretsPersistence = {
    sops.age.keyFile = "/.persist/var/lib/sops/age/keys.txt";
    environment.persistence."/.persist".directories = [ "/var/lib/sops" ];
  };

  flake.modules.homeManager.secrets = { pkgs, ... }: {
    home.packages = [ pkgs.sops ];
  };
}
