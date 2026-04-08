{ ... }:

{
  nixie.docker = {
    description = "virtualization container environment docker";

    nixos = { ... }: {
      virtualisation.docker = {
        enable = true;
        storageDriver = "btrfs";
      };
    };
  };
}
