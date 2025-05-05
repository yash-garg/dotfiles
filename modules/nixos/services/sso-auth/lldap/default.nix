{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.lldap;
in
{
  options.${namespace}.services.lldap = {
    enable = mkEnableOption "Enable lldap user directory";
    domain = mkOpt types.str "yashgarg.dev" "Base domain for lldap";
    host = mkOpt types.str "zenith" "Host for lldap";
  };

  config = mkIf cfg.enable {
    age.secrets = {
      jwtPrivate = {
        file = getSecret "jwt" "${cfg.host}/lldap";
        owner = "lldap";
        mode = "0600";
      };
      userPassword = {
        file = getSecret "user" "${cfg.host}/lldap";
        owner = "lldap";
        mode = "0600";
      };
      keySeed = {
        file = getSecret "key-seed" "${cfg.host}/lldap";
        owner = "lldap";
        mode = "0600";
      };
    };

    services = {
      lldap = enabled // {
        environment = {
          LLDAP_JWT_SECRET_FILE = config.age.secrets.jwtPrivate.path;
          LLDAP_LDAP_USER_PASS_FILE = config.age.secrets.userPassword.path;
          LLDAP_KEY_SEED_FILE = config.age.secrets.keySeed.path;
        };
        settings = {
          ldap_base_dn = "dc=${concatStringsSep ",dc=" (splitString "." cfg.domain)}";
          ldap_user_email = "alt@${cfg.domain}";
          database_url = "postgresql://lldap@localhost/lldap?host=/run/postgresql";
        };
      };

      traefik.dynamicConfigOptions.http = {
        routers.lldap = {
          rule = "Host(`users.${cfg.domain}`)";
          entryPoints = [ "websecure" ];
          service = "lldap";
          middlewares = [ "auth" ];
          tls.certResolver = "letsencrypt";
        };
        services.lldap.loadBalancer = {
          servers = [
            { url = "http://localhost:${toString config.services.lldap.settings.http_port}"; }
          ];
        };
      };
    };

    users = {
      users.lldap = {
        group = "lldap";
        isSystemUser = true;
      };
      groups.lldap = { };
    };
  };
}
