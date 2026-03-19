{ ... }:

{
  nixie.jetbrains= {
    description = "JetBrains IDEs";

    home = { pkgs, ... }: {
      home.packages = [
        (pkgs.jetbrains.plugins.addPlugins pkgs.jetbrains.idea ["github-copilot"])
      ];
    };
  };
}
