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
      "--json"
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

  resticNotifyScript = pkgs.writeShellScript "restic-notify" ''
    export PATH="${
      lib.makeBinPath [
        pkgs.bash
        pkgs.coreutils
        pkgs.curl
        pkgs.systemd
        pkgs.gnugrep
        pkgs.gawk
      ]
    }:$PATH"

    exec ${pkgs.bash}/bin/bash ${snowfall.fs.get-file "scripts/restic-notify"} "$@"
  '';

  # Post-backup notification hook
  postHook = app: ''
    ${resticNotifyScript} "${app}" "$EXIT_STATUS"
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
