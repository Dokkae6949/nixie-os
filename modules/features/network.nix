{
  flake.modules.nixos.network = {
    networking.networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };

    services.resolved.enable = true;
  };

  flake.modules.nixos.networkPersistence = {
    environment.persistence."/.persist".directories = [
      "/etc/NetworkManager/system-connections"
    ];
  };
}
