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
  srv = config.${namespace}.services;
  cfg = srv.postgres;
in
{
  options.${namespace}.services.postgres = {
    enable = mkEnableOption "Enable postgresql service";
    package = mkOpt types.package pkgs.postgresql_18 "The package to use for postgresql";
    backup = {
      enable = mkEnableOption "Enable restic backup for PostgreSQL";
      url =
        mkOpt types.str "06a4a54ded73aeb04fb12c679a65ed78.r2.cloudflarestorage.com"
          "Restic repository URL";
    };
  };

  config = mkIf cfg.enable {
    services = {
      postgresql = enabled // {
        inherit (cfg) package;
        enableTCPIP = true;
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
          {
            name = "yash";
            ensureClauses.superuser = true;
          }
        ];
      };

      postgresqlBackup = mkIf cfg.backup.enable {
        inherit (cfg.backup) enable;
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

      restic.backups.postgresql = mkIf (cfg.backup.enable && srv.restic.enable) (
        srv.restic.mkBackup "postgresql" {
          paths = [ "${config.services.postgresqlBackup.location}/all.sql" ];
          repository = "s3:${cfg.backup.url}/postgresql";
        }
      );
    };
  };
}
