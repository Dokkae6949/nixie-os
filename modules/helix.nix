{ ... }:

{
  nixie.helix = {
    description = "terminal editor similar to vim";

    home = { ... }: {
      programs.helix = {
        enable = true;
        defaultEditor = true;

        settings = {
          theme = "gruvbox";

          editor = {
            line-number = "relative";
            text-width = 100;
            complection-timeout = 10;
          };
        };
      };
    };
  };
}
