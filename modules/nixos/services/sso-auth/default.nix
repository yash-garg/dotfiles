{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.sso;
in
{
  options.${namespace}.sso = {
    enable = mkEnableOption "Enable SSO Auth for Services";
  };

  config = mkIf cfg.enable {
    dots.services = {
      authelia = enabled;
      lldap = enabled;
    };

    services.postgresql = enabled // {
      ensureDatabases = [
        "authelia-main"
        "lldap"
      ];
      ensureUsers = [
        {
          name = "root";
          ensureClauses.superuser = true;
        }
        {
          name = "authelia-main";
          ensureDBOwnership = true;
        }
        {
          name = "lldap";
          ensureDBOwnership = true;
        }
      ];
    };

    systemd.services.authelia-main =
      let
        dependencies = [
          "lldap.service"
          "postgresql.service"
        ];
      in
      {
        after = dependencies;
        requires = dependencies;
      };
  };
}
