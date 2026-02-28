{ __findFile, ... }:

{
  den.hosts.x86_64-linux.shiina.users.kurisu = { };

  den.aspects.kurisu = {
    includes = [
    ];

    nixos = { pkgs, config, ... }: {
      sops.secrets."users/kurisu/password_hash" = {
        sopsFile = ../../../secrets/users/kurisu.yaml;
        neededForUsers = true;
      };

      users.mutableUsers = false;
      users.users.kurisu = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets."users/kurisu/password_hash".path;

        shell = pkgs.fish;

        extraGroups = [ "wheel" ];
      };

      programs.fish.enable = true;
    };

    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        htop
        helix
      ];

      programs.fish.enable = true;
    };
  };
}
