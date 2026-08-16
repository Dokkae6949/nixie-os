{ ... }:

{
  nixie.firefox= {
    nixos = { ... }: { };

    home = { config, ... }: {
      programs.firefox = {
        enable = true;
        configPath = "${config.xdg.configHome}/mozilla/firefox";
      };
    };
  };
}
