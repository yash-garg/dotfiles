{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace};
in
{
  services = {
    postgresql = enabled // {
      authentication = mkOverride 10 ''
        local all  all                 trust
        host  all  all  127.0.0.1/32   trust
        host  all  all  ::1/128        trust
      '';

      ensureDatabases =
        (optionals cfg.sso.enable [
          "authelia-main"
          "lldap"
        ])
        ++ (optionals cfg.services.linkding.enable [
          cfg.services.linkding.database.name
        ]);

      ensureUsers = [
        {
          name = "root";
          ensureClauses.superuser = true;
        }
      ]
      ++ (optionals cfg.sso.enable [
        {
          name = "authelia-main";
          ensureDBOwnership = true;
        }
        {
          name = "lldap";
          ensureDBOwnership = true;
        }
      ])
      ++ (optionals cfg.services.linkding.enable [
        {
          name = cfg.services.linkding.database.user;
          ensureDBOwnership = true;
        }
      ]);
    };

    postgresqlBackup = enabled // {
      backupAll = true;
      compression = "none";
      pgdumpOptions = "-c";
      startAt = "*-*-* 00:00:00";
    };
  };
}
