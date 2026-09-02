{
  flake.modules.homeManager.matrix = {
    programs.element-desktop.enable = true;

    # Electron does not recognize Niri as a desktop with a supported Secret
    # Service implementation. Override only the launcher, keeping the upstream
    # Element package unchanged.
    xdg.desktopEntries.element-desktop = {
      name = "Element";
      genericName = "Matrix Client";
      comment = "Feature-rich client for Matrix.org";
      icon = "element";
      exec = "element-desktop --password-store=gnome-libsecret %u";
      terminal = false;
      type = "Application";
      categories = [
        "Network"
        "InstantMessaging"
        "Chat"
      ];
      mimeType = [
        "x-scheme-handler/element"
        "x-scheme-handler/io.element.desktop"
      ];
      settings = {
        StartupWMClass = "Element";
      };
    };
  };
}
