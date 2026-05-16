{ ... }:

{
  nixie.postgresql = {
    nixos = { pkgs, ... }: {
      services.postgresql = {
        enable = true;

        package = pkgs.postgresql_18;

        enableTCPIP = true;
        authentication = pkgs.lib.mkOverride 10 ''
          #type database  DBuser    origin-address  auth-method
          local all       postgres                  trust
          host  all       all       127.0.0.1/32    trust
          host  all       all       ::1/128         trust
          #Allow Docker bridge network (default Docker network)
          host  all       all       172.17.0.0/16   trust
        '';
      };
    };
  };
}
