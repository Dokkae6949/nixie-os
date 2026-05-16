{ ... }:

{
  nixie.docker = {
    nixos = { ... }: {
      virtualisation.docker = {
        enable = true;
        storageDriver = "btrfs";
      };
    };
  };
}
