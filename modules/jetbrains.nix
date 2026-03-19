{ inputs, ... }:

{
  nixie.jetbrains= {
    description = "JetBrains IDEs";

    home = { pkgs, ... }: {
      home.packages = let
        inherit (pkgs.jetbrains) idea;
        plugins = inputs.nix-jetbrains-plugins.lib.pluginsForIde pkgs idea [
          "com.github.copilot"
        ];
      in [
        (pkgs.jetbrains.plugins.addPlugins idea (lib.attrValues plugins))
      ];
    };
  };
}
