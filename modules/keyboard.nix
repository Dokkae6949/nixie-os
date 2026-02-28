{
  nixi.keyboard = {
    nixos = { ... }: {
      console.useXkbConfig = true;

      services = {
        xserver.xkb.layout = "at";

        keyd = {
          enable = true;

          keyboards.default = {
            ids = [ "*" ];
            settings = {
              # Overload capslock to control when held, escape when tapped.
              main = {
                capslock = "overload(control, escape)";
                esc = "capslock";
                kpenter = "enter";
              };
            };
          };
        };
      };
    };
  };
}
