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
      postgresql = defaults // {
        paths = [ "${config.services.postgresqlBackup.location}/all.sql" ];
        repository = "s3:${r2_url}/postgresql";
      };
    };
  };
}
