{ inputs, den, ... }:

{
  _module.args.__findFile = den.lib.__findFile;

  imports = [
    inputs.den.flakeModule

    (inputs.den.namespace "nixi" true)
  ];

  den.default.nixos.system.stateVersion = "25.05";
  den.default.homeManager.home.stateVersion = "25.05";
}
