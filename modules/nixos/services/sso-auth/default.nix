{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.sso;
in
{
  options.${namespace}.services.sso = {
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

    services.postgresql = {
      ensureDatabases = [
        "authelia-main"
        "lldap"
      ];
      ensureUsers = [
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

    systemd.services = {
      authelia-main = {
        after = [
          "lldap.service"
          "postgresql.service"
        ];
        requires = [
          "lldap.service"
          "postgresql.service"
        ];
      };
      lldap = {
        after = [ "postgresql.service" ];
        requires = [ "postgresql.service" ];
      };
    };
  };
}
