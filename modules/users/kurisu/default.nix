{ lib, ... }:

{
  nixie.users.kurisu = {
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
        extraGroups = [ "wheel" ];
      };

      programs.fish.enable = lib.mkDefault true;
    };

    home = { pkgs, ... }: {
      home.packages = with pkgs; [
        htop
        helix
      ];

      programs.fish.enable = true;
    };
  };
}
