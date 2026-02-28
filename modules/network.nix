{
  nixi.network = {
    nixos = { ... }: {
      networking.networkmanager = {
        enable = true;
      };
    };
  };
}
