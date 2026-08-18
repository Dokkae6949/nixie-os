{
  flake.modules.nixos.sudo.security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    extraConfig = "Defaults lecture = never";
  };
}
