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

  # Common backup defaults
  backupDefaults = {
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
    progressFps = 0.1;
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

  # Post-backup notification hook
  postHook = app: ''
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

  # Helper function to create backup configurations
  mkBackup =
    name: overrides:
    backupDefaults
    // overrides
    // {
      backupCleanupCommand = postHook name;
    };
in
{
  options.${namespace}.services.restic = {
    enable = mkEnableOption "Enable restic backup";

    # Helper function exposed to other modules
    mkBackup = mkOption {
      type = types.functionTo (types.functionTo types.attrs);
      default = mkBackup;
      description = "Helper function to create restic backup configurations";
      readOnly = true;
    };

    # Common backup defaults exposed to other modules
    defaults = mkOption {
      type = types.attrs;
      default = backupDefaults;
      description = "Common backup defaults";
      readOnly = true;
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.restic-env = {
      sopsFile = snowfall.fs.get-file "secrets/restic.env";
      format = "dotenv";
    };

    # Individual service modules will now define their own backups
    # using the exposed mkBackup helper function
  };
}
