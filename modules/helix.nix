{ ... }:

{
  nixie.helix = {
    home = { ... }: {
      programs.helix = {
        enable = true;
        defaultEditor = true;

        settings = {
          theme = "gruvbox";

          editor = {
            line-number = "relative";
            text-width = 100;
            completion-timeout = 10;
          };
        };
      };
    };
  };
}
