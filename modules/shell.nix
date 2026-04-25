{ ... }:

{
  nixie.shell= {
    description = "shell configuration";

    home = { ... }: {
      programs.eza.enable = true;
      
      programs.fish = {
        enable = true;

        shellInit = ''
          set fish_greeting
        '';

        shellAliases = {
          # l → long format, include dotfiles
          l = "eza -l --all --color=always --icons=always --git";

          # ll → long format, exclude dotfiles
          ll = "eza -l --color=always --icons=always --git";

          # ls → classic grid view
          ls = "eza --grid --color=always --icons=always";

          # lt → tree view with metadata
          lt = "eza --tree -l --color=always --icons=always --git";
        };
      };
    };
  };
}
