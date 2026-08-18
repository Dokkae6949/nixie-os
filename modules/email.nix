{ ... }:

{
  nixie.email = {
    home = { inputs, pkgs, ... }:
      let
        fastmailPkgs = import inputs.fastmail-nixpkgs {
          system = pkgs.system;

          config.allowUnfreePredicate = pkg:
            builtins.elem (pkgs.lib.getName pkg) [
              "fastmail-desktop"
            ];
        };
      in
      {
        home.packages = [
          fastmailPkgs.fastmail-desktop
        ];
      };
  };
}
