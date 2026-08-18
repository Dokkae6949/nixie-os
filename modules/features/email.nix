{ inputs, ... }:

{
  flake.modules.homeManager.email = { pkgs, ... }:
    let
      fastmailPkgs = import inputs.fastmail-nixpkgs {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfreePredicate = package:
          pkgs.lib.getName package == "fastmail-desktop";
      };
    in
    {
      home.packages = [ fastmailPkgs.fastmail-desktop ];
    };
}
