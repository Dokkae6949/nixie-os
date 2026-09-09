{
  flake.modules.nixos.shell.programs.fish.enable = true;

  flake.modules.homeManager.shell = {
    programs.eza.enable = true;

    programs.starship = {
      enable = true;
      enableFishIntegration = true;
    };

    programs.fish = {
      enable = true;
      shellInit = "set fish_greeting";

      shellAliases = {
        l = "eza -l --all --color=always --icons=always --git";
        ll = "eza -l --color=always --icons=always --git";
        ls = "eza --grid --color=always --icons=always";
        lt = "eza --tree -l --color=always --icons=always --git";
      };
    };
  };
}
