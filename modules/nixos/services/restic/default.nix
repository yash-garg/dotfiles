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
  cfg = srv.restic;
  defaults = {
    initialize = true;
    environmentFile = config.sops.secrets.restic-env.path;
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
    repoUrl =
      mkOpt types.str "06a4a54ded73aeb04fb12c679a65ed78.r2.cloudflarestorage.com"
        "The URL of the R2 bucket";
  };

  config = mkIf cfg.enable {
    sops.secrets.restic-env = {
      sopsFile = snowfall.fs.get-file "secrets/restic.env";
      format = "dotenv";
    };

    services.restic.backups = {
      actual-budget =
        let
          actualCfg = config.services.actual;
        in
        mkIf actualCfg.enable (
          defaults
          // {
            backupCleanupCommand = post-hook "budget";
            paths = [
              actualCfg.settings.serverFiles
              actualCfg.settings.userFiles
            ];
            repository = "s3:${cfg.repoUrl}/actual-budget";
          }
        );

      immich =
        let
          immichCfg = srv.immich;
        in
        mkIf immichCfg.enable (
          defaults
          // {
            backupCleanupCommand = post-hook "photos";
            paths = [ immichCfg.mediaDir ];
            repository = "s3:${cfg.repoUrl}/immich-backup";
            timerConfig.OnCalendar = "weekly";
          }
        );

      minecraft =
        let
          mcCfg = srv.minecraft-server;
        in
        mkIf mcCfg.enable (
          defaults
          // {
            backupCleanupCommand = post-hook "minecraft";
            paths = [ mcCfg.dataDir ];
            repository = "s3:${cfg.repoUrl}/minecraft";
            timerConfig.OnCalendar = "weekly";
          }
        );

      paperless-ngx =
        let
          paperlessCfg = srv.paperless;
        in
        mkIf paperlessCfg.enable (
          defaults
          // {
            backupCleanupCommand = post-hook "documents";
            paths = [ paperlessCfg.mediaDir ];
            repository = "s3:a69e81e6342baaeed47710799b04477a.r2.cloudflarestorage.com/paperless-ngx";
            timerConfig.OnCalendar = "weekly";
          }
        );

      postgresql = mkIf config.services.postgresql.enable (
        defaults
        // {
          backupCleanupCommand = post-hook "postgresql";
          paths = [ "${config.services.postgresqlBackup.location}/all.sql" ];
          repository = "s3:${cfg.repoUrl}/postgresql";
        }
      );
    };
  };
}
