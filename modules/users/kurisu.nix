{
  flake.modules.nixos.kurisu = { config, pkgs, ... }: {
    sops.secrets."users/kurisu/password_hash" = {
      sopsFile = ../../secrets/users/kurisu.yaml;
      neededForUsers = true;
    };

    users.mutableUsers = false;
    users.users.kurisu = {
      uid = 1000;
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPasswordFile = config.sops.secrets."users/kurisu/password_hash".path;
      shell = pkgs.fish;
    };
  };

  flake.modules.homeManager.kurisu = {
    home = {
      username = "kurisu";
      homeDirectory = "/home/kurisu";
      stateVersion = "25.11";
    };

    programs.git = {
      enable = true;
      settings = {
        user.email = "finnliry@gmail.com";
        user.name = "Dokkae6949";
      };
    };
  };
}
