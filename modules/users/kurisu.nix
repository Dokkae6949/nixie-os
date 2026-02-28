{ __findFile, ... }:

{
  den.hosts.x86_64-linux.shiina.users.kurisu = { };

  den.aspects.kurisu = {
    includes = [
      <nixi/secrets>
    ];

    nixos = { pkgs, ... }: {
      users.users.kurisu = {
        isNormalUser = true;
        initialPassword = "12341234";
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
