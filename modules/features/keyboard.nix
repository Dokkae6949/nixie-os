{
  flake.modules.nixos.keyboard = {
    console.useXkbConfig = true;
    services.xserver.xkb.layout = "at";

    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings.main = {
          capslock = "overload(control, escape)";
          esc = "capslock";
          kpenter = "enter";
        };
      };
    };
  };
}
