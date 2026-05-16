{ ... }:

{
  nixie.users.kurisu = {
    uid = 1000;
    groups = [ "wheel" "docker" ];

    profiles.default = {
      features = {
        helium = {};
        firefox = {};
        jetbrains = {};
        direnv = {};
        fonts = {};
        discord = {};
        spotify = {};
        helix = {};
        shell = {};
      };
    
      home = { pkgs, ... }: {
        home.packages = with pkgs; [
          htop
          zellij
        ];

        programs.git = {
          enable = true;

          settings = {
            user.email = "finnliry@gmail.com";
            user.name = "Dokkae6949";
          };
        };
      };
    };

    nixos = { config, lib, pkgs, ... }: {
      sops.secrets = {
        "users/kurisu/password_hash" = {
          sopsFile       = ../../../secrets/users/kurisu.yaml;
          neededForUsers = true;
        };

        "users/kurisu/ssh/id_ed25519" = {
          sopsFile = ../../../secrets/users/kurisu.yaml;
        };
      };

      users.mutableUsers = false;
      users.users.kurisu.hashedPasswordFile = config.sops.secrets."users/kurisu/password_hash".path;
      users.users.kurisu.shell = pkgs.fish;
      programs.fish.enable = lib.mkDefault true;
    };
  };
}
