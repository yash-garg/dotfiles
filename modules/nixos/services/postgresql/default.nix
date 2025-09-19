{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.postgres;
in
{
  options.${namespace}.services.postgres = {
    enable = mkEnableOption "Enable postgresql service";
  };

  config = mkIf cfg.enable {
    services = {
      postgresql = enabled // {
        enableTCPIP = true;
        package = pkgs.postgresql_17;
        authentication = mkOverride 10 ''
          local all  all                 trust
          host  all  all  127.0.0.1/32   trust
          host  all  all  ::1/128        trust
        '';
        ensureUsers = [
          {
            name = "root";
            ensureClauses.superuser = true;
          }
        ];
      };

      postgresqlBackup = enabled // {
        backupAll = true;
        compression = "none";
        startAt = "*-*-* 00:00:00";
      };

      prometheus = {
        exporters.postgres = {
          enable = true;
          port = ports.exporters.postgres;
          runAsLocalSuperUser = true;
        };
        scrapeConfigs = [
          {
            job_name = "postgres_exporter";
            static_configs = [ { targets = [ "127.0.0.1:${toString ports.exporters.postgres}" ]; } ];
          }
        ];
      };
    };
  };
}
