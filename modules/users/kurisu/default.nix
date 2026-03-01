{ lib, ... }:

{
  nixie.users.kurisu = {
    # NixOS module for kurisu — creates the system user account.
    # Use lib.mkDefault for any value the host should be able to override.
    nixos = { config, lib, pkgs, ... }: {
      sops.secrets."users/kurisu/password_hash" = {
        sopsFile       = ../../../secrets/users/kurisu.yaml;
        neededForUsers = true;
      };

      sops.secrets."users/kurisu/ssh/id_ed25519" = {
        sopsFile = ../../../secrets/users/kurisu.yaml;
      };

      users.mutableUsers = false;
      users.users.kurisu = {
        isNormalUser       = true;
        hashedPasswordFile = config.sops.secrets."users/kurisu/password_hash".path;
        shell              = pkgs.fish;
        extraGroups        = [ "wheel" ];
      };

      programs.fish.enable = lib.mkDefault true; # system-wide install (login shell)
    };

    # home-manager module for kurisu — applied as home-manager.users.kurisu.
    # Takes priority over any host-level home defaults (sharedModules).
    # Note: home.stateVersion is set via the host's home defaults (lib.mkDefault "25.11").
    home = { pkgs, ... }: {
      home.packages = with pkgs; [
        htop
        helix
      ];

      # User-level Fish config (completions, init, plugins — separate from NixOS system install).
      programs.fish.enable = true;
    };
  };
}
