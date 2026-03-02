{
  nixie.sudo = {
    description = "sudo configuration";

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
