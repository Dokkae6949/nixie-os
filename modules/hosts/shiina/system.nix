{
  flake.modules.nixos.shiina = { config, ... }: {
    sops.secrets."hosts/shiina/ssh/host_ed25519_key" = {
      sopsFile = ../../../secrets/hosts/shiina.yaml;
    };

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
