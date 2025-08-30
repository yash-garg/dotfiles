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
    sops.secrets.lldap-env = {
      sopsFile = snowfall.fs.get-file "secrets/lldap.env";
      format = "dotenv";
      owner = config.users.users.lldap.name;
      group = config.users.groups.lldap.name;
      mode = "0600";
    };

    services = {
      lldap = enabled // {
        environmentFile = config.sops.secrets.lldap-env.path;
        settings = {
          http_port = ports.lldap;
          ldap_base_dn = "dc=${concatStringsSep ",dc=" (splitString "." cfg.domain)}";
          ldap_user_email = "alt@${cfg.domain}";
          ldap_user_pass = "$LLDAP_USER_PASSWORD";
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
