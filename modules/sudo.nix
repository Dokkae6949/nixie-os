{
  nixie.sudo = {
    nixos = { ... }: {
      security.sudo = {
        enable = true;
        wheelNeedsPassword = true;

        extraConfig = ''
          Defaults lecture = never
        '';
      };
    };
  };
}
