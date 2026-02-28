{ lib, den, inputs, ... }:

let
  persist = { class, aspect-chain }: den._.forward {
    each = lib.singleton true;
    fromClass = _: "persist";
    intoClass = _: class;
    intoPath = _: [ "environment" "persistence" "/.persist" ];
    fromAspect = _: lib.head aspect-chain;
    guard = { options, ... }: options ? environment.persistence;
  };
in
{
  nixi.aspects.persist = {
    includes = [ persist ];

    nixos = { lib, ... }: {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      environment.persistence."/.persist" = {
        hideMounts = true;

        directories = [
          "/etc/nixos"
          "/etc/NetworkManager/system-connections"

          "/var/lib/nixos"
        ];

        files = [
          "/etc/machine-id"
        ];
      };

      # Make sure persisted storage is available before consumers use it.
      fileSystems."/.persist".neededForBoot = lib.mkDefault true;
    };
  };
}
