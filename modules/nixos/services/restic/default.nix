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
  cfg = config.${namespace}.services.restic;
  srv = config.services;
  r2_url = "06a4a54ded73aeb04fb12c679a65ed78.r2.cloudflarestorage.com";
  defaults = {
    initialize = true;
    passwordFile = config.age.secrets.restic-password.path;
    environmentFile = config.age.secrets.restic-env.path;
    exclude = [
      ".cache"
      ".git"
    ];
    extraBackupArgs = [
      "--skip-if-unchanged"
      "--verbose"
    ];
    pruneOpts = [
      "--keep-daily 2"
      "--keep-weekly 1"
      "--keep-monthly 1"
    ];
    timerConfig = {
      OnCalendar = "*-*-* 00:30";
      Persistent = true;
    };
  };
  post-hook = app: ''
    if [ $EXIT_STATUS -ne 0 ]; then
      ${pkgs.curl}/bin/curl -H "Content-Type: application/json" \
        -X POST \
        -d "{\"content\": \"❌ Backup **${app}** failed!\"}" \
        "$DISCORD_WEBHOOK"

      ${pkgs.curl}/bin/curl -H "Content-Type: text/plain" \
        -H "X-Title: Backup ${app}" \
        -H "X-Priority: 5" \
        -H "X-Tags: x,warning,backup" \
        -d "Backup ${app} failed!" \
        "$NTFY_URL"
    else
      ${pkgs.curl}/bin/curl -H "Content-Type: application/json" \
        -X POST \
        -d "{\"content\": \"✅ Backup **${app}** successful!\"}" \
        "$DISCORD_WEBHOOK"

      ${pkgs.curl}/bin/curl -H "Content-Type: text/plain" \
        -H "X-Title: Backup ${app}" \
        -H "X-Priority: 3" \
        -H "X-Tags: white_check_mark,backup" \
        -d "Backup ${app} successful!" \
        "$NTFY_URL"
    fi
  '';
in
{
  options.${namespace}.services.restic = {
    enable = mkEnableOption "Enable restic backup";

    host = mkOption {
      type = types.str;
      description = "Host name of the system";
    };
  };

  config = mkIf cfg.enable {
    age.secrets = {
      restic-password.file = getSecret "restic-password" cfg.host;
      restic-env.file = getSecret "restic.env" cfg.host;
    };

    services.restic.backups = {
      actual-budget = mkIf srv.actual.enable (
        defaults
        // {
          backupCleanupCommand = post-hook "actual-budget";
          paths = [
            srv.actual.settings.serverFiles
            srv.actual.settings.userFiles
          ];
          repository = "s3:${r2_url}/actual-budget";
        }
      );

      postgresql = mkIf srv.postgresql.enable (
        defaults
        // {
          backupCleanupCommand = post-hook "postgresql";
          paths = [ "${srv.postgresqlBackup.location}/all.sql" ];
          repository = "s3:${r2_url}/postgresql";
        }
      );
    };
  };
}
