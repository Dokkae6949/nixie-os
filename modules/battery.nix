{
  nixi.battery = {
    nixos = { ... }: {
      services = {
        upower.enable = true;
      };
    };
  };
}
