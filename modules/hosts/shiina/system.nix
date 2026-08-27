{
  flake.modules.nixos.shiina = { config, ... }: {
    sops.secrets."hosts/shiina/ssh/host_ed25519_key" = {
      sopsFile = ../../../secrets/hosts/shiina.yaml;
    };

    sops.secrets."hosts/shiina/tailscale/auth_key" = {
      sopsFile = ../../../secrets/hosts/shiina.yaml;
    };

    services.tailscale.authKeyFile =
      config.sops.secrets."hosts/shiina/tailscale/auth_key".path;

    services.openssh.hostKeys = [
      {
        path = config.sops.secrets."hosts/shiina/ssh/host_ed25519_key".path;
        type = "ed25519";
      }
    ];

    # Local authorization policy: Kurisu operates Docker on this host.
    users.groups.docker.members = [ "kurisu" ];
    virtualisation.docker.storageDriver = "btrfs";

    system.stateVersion = "25.11";
  };
}
