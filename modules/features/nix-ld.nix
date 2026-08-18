{
  flake.modules.nixos.nix-ld = { pkgs, ... }: {
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        zlib
        glib
        nss
        nspr
        dbus
        atk
        at-spi2-atk
        cups
        gtk3
        pango
        cairo
        expat
        libxkbcommon
        libdrm
        libgbm
        mesa
        alsa-lib
        libx11
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxrandr
        libxcb
      ];
    };
  };
}
