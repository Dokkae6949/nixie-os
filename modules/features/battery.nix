{
  flake.modules.nixos.battery = {
    services.upower.enable = true;

    services.tlp = {
      enable = true;
      pd.enable = true;
    };
  };
}
