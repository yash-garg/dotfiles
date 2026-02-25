{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.joplin;
in
{
  options.${namespace}.services.joplin = {
    enable = mkEnableOption "Joplin: Note Taking App";
    database = {
      name = mkOpt types.str "joplin" "The name of the database for joplin";
      user = mkOpt types.str "joplin" "The user of the database for joplin";
    };
    domain = mkOpt types.str "ipx.ovh" "The domain name for joplin";
    port = mkOpt types.int ports.joplin "The port for joplin";
    version = mkOpt types.str "3.5.2" "The version of joplin";
  };

  config = mkIf cfg.enable {
    services.postgresql = {
      ensureDatabases = [ cfg.database.name ];
      ensureUsers = [
        {
          name = cfg.database.user;
          ensureDBOwnership = true;
        }
      ];
    };

    virtualisation.oci-containers.containers.joplin = {
      image = "joplin/server:${cfg.version}";
      autoStart = true;
      ports = [ "${toString cfg.port}:22300" ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "/run/postgresql:/run/postgresql"
      ];
      environment = {
        APP_PORT = "22300";
        APP_BASE_URL = "https://notes.${cfg.domain}";
        API_BASE_URL = "https://notes.${cfg.domain}";
        DB_CLIENT = "pg";
        POSTGRES_DATABASE = cfg.database.name;
        POSTGRES_USER = cfg.database.user;
        POSTGRES_PORT = "5432";
        POSTGRES_HOST = "/run/postgresql";
        TZ = "Asia/Kolkata";
      };
    };

    dots.services.caddy.services.notes = {
      inherit (cfg) domain;
      upstream = "localhost:${toString cfg.port}";
    };
  };
}
