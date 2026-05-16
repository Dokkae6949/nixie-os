{ ... }:

{
  nixie.fonts = {
    home = { pkgs, ... }: {
      fonts.fontconfig.enable = true;

      home.packages = with pkgs; [
        font-awesome
        noto-fonts
        nerd-fonts.zed-mono
        nerd-fonts.jetbrains-mono
        nerd-fonts.noto
      ];
    };
  };
}
