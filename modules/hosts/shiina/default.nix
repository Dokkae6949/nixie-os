{ inputs, lib, dendritic, ... }:

{
  systems = [ "x86_64-linux" ];

  flake.nixosConfigurations.shiina = dendritic.mkSystem {
    system = "x86_64-linux";

    extraModules = [
      inputs.disko.nixosModules.disko

      ./_config

      ({ config, ... }: {
        # ── Enabled features ────────────────────────────────────────────────
        nixie.battery.enable      = true;
        nixie.keyboard.enable     = true;
        nixie.network.enable      = true;
        nixie.niri.enable         = true;
        nixie.persist.enable      = true;
        nixie.secrets.enable      = true;
        nixie.users-kurisu.enable = true;

        # ── Host-specific secrets ────────────────────────────────────────────
        sops.secrets."hosts/shiina/ssh/host_ed25519_key" = {
          sopsFile = ../../../secrets/hosts/shiina.yaml;
        };

        services.openssh.hostKeys = [
          { path = config.sops.secrets."hosts/shiina/ssh/host_ed25519_key".path;
            type = "ed25519";
          }
        ];

        # ── Nix settings ─────────────────────────────────────────────────────
        nix =
          let flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
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
      })
    ];
  };
}
