{ inputs, ... }:

{
  perSystem = { pkgs, ... }: {
    packages.shiina-vm = pkgs.writeShellApplication {
      name = "shiina-vm";
      text = let
        host = inputs.self.nixosConfigurations.shiina.config;
      in ''
        ${host.system.build.vm}/bin/run-${host.networking.hostName}-vm "$@"
      '';
    };
  };
}
