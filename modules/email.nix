{ ... }:

{
  nixie.email = {
    home = { pkgs, ... }: {
      home.packages = with pkgs; [
        fastmail-desktop
      ];
    };
  };
}
