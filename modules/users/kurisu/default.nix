{ lib, ... }:

{
  nixie.users-kurisu = {
    options = {
      enable = lib.mkEnableOption "kurisu user account";
    };

    nixos = { config, lib, pkgs, ... }: lib.mkIf config.nixie.users-kurisu.enable {
      sops.secrets."users/kurisu/password_hash" = {
        sopsFile      = ../../../secrets/users/kurisu.yaml;
        neededForUsers = true;
      };

      sops.secrets."users/kurisu/ssh/id_ed25519" = {
        sopsFile = ../../../secrets/users/kurisu.yaml;
      };

      users.mutableUsers = false;
      users.users.kurisu = {
        isNormalUser      = true;
        hashedPasswordFile = config.sops.secrets."users/kurisu/password_hash".path;
        shell             = pkgs.fish;
        extraGroups       = [ "wheel" ];
      };

      programs.fish.enable = true;

      home-manager.users.kurisu = { pkgs, ... }: {
        home.packages = with pkgs; [
          htop
          helix
        ];

        programs.fish.enable = true;

        home.stateVersion = "25.11";
      };
    };
  };
}
