{ lib, ... }:

{
  nixie.users.kurisu = {
    features = [
      "helium"
      "firefox"
      "jetbrains"
      "direnv"
      "fonts"
      "discord"
      "spotify"
      "helix"
    ];
    
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
      users.users.kurisu = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets."users/kurisu/password_hash".path;
        shell = pkgs.fish;
        extraGroups = [ "wheel" "docker" ];
      };

      programs.fish.enable = lib.mkDefault true;
    };

    home = { pkgs, ... }: {
      home.packages = with pkgs; [
        htop
        zellij
      ];

      programs.fish = {
        enable = true;

        shellInit = ''
          set fish_greeting
        '';
      };
      programs.git = {
        enable = true;

        settings = {
          user.email = "finnliry@gmail.com";
          user.name = "Dokkae6949";
        };
      };
    };
  };
}
