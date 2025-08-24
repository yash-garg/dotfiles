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
    domain = mkOpt types.str "ipx.ovh" "Base domain for SSO Auth";
  };

  config = mkIf cfg.enable {
    dots.services = {
      authelia = enabled // {
        inherit (cfg) domain;
      };
      lldap = enabled // {
        inherit (cfg) domain;
      };
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
      authentication = mkOverride 10 ''
        local all  all                 trust
        host  all  all  127.0.0.1/32   trust
        host  all  all  ::1/128        trust
      '';
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
