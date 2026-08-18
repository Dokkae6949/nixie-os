{
  flake.modules.homeManager.cliTools = { pkgs, ... }: {
    home.packages = with pkgs; [
      htop
      zellij
    ];
  };
}
