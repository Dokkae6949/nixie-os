{ config, inputs, ... }:

{
  systems = [ "x86_64-linux" ];

  flake.nixosConfigurations.shiina = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = with config.flake.modules.nixos; [
      base
      laptop
      desktop
      development
      impermanent
      kurisu
      shiina

      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.kurisu.imports = with config.flake.modules.homeManager; [
            base
            desktop
            development
            kurisu
          ];
        };
      }
    ];
  };
}
