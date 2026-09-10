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
        l = "eza -l --all --color=always --icons=always --git --group-directories-first";
        ll = "eza -l --color=always --icons=always --git --group-directories-first";
        ls = "eza --grid --color=always --icons=always --group-directories-first";
        lt = "eza --tree -l --color=always --icons=always --git --group-directories-first";
      };
    };
  };
}
