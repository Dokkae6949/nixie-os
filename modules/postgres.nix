{ ... }:

{
  nixie.postgresql = {
    description = "PostgreSQL relational database";

    nixos = { pkgs, ... }: {
      services.postgresql = {
        enable = true;

        package = pkgs.postgresql_18;
      };
    };
  };
}
