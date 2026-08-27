{
  flake.modules.nixos.tailscale = {
    services.tailscale = {
      enable = true;

      # Allow direct peer-to-peer connections instead of relying on DERP when
      # the local network permits UDP hole punching.
      openFirewall = true;
    };

    # Tailscale ACLs remain the network-level authorization boundary. Trusting
    # its interface lets services be reached without opening them on LAN/WAN.
    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };

  flake.modules.nixos.tailscalePersistence = {
    environment.persistence."/.persist".directories = [
      "/var/lib/tailscale"
    ];
  };
}
