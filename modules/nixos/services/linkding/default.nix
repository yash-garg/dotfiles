{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.linkding;
in
{
  options.${namespace}.services.linkding = {
    enable = mkEnableOption "Easy to use self-hosted bookmark manager";

    database = {
      enable = mkEnableOption "Enable the linkding database";
      user = mkOption {
        type = types.str;
        default = "linkding";
        description = "The user for the linkding database";
      };
      name = mkOption {
        type = types.str;
        default = "linkding";
        description = "The database for the linkding database";
      };
    };

    host = mkOption {
      type = types.str;
      default = "zenith";
      description = "The host name for the secrets";
    };

    proxy = {
      enable = mkEnableOption "Enable the linkding service";
      domain = mkOption {
        type = types.str;
        default = "yashgarg.dev";
        description = "The domain name for the linkding service";
      };
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.linkding-env = {
      sopsFile = snowfall.fs.get-file "secrets/linkding.env";
      format = "dotenv";
    };

    systemd.services.docker-linkding = {
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];
    };

    virtualisation.oci-containers.containers.linkding = {
      image = "sissbruecker/linkding:latest";
      autoStart = true;
      ports = [ "${toString ports.linkding}:9090" ];
      volumes = [
        "/var/lib/linkding:/app/data"
        "/run/postgresql:/run/postgresql/"
      ];
      environmentFiles = [ config.sops.secrets.linkding-env.path ];
      environment = {
        LD_CSRF_TRUSTED_ORIGINS = "https://links.${cfg.proxy.domain}";
        LD_DB_DATABASE = cfg.database.name;
        LD_DB_ENGINE = "postgres";
        LD_DB_HOST = "/run/postgresql/";
        LD_DB_USER = cfg.database.user;
        LD_ENABLE_AUTH_PROXY = "False";
        LD_AUTH_PROXY_USERNAME_HEADER = "HTTP_REMOTE_USER";
        LD_AUTH_PROXY_LOGOUT_URL = "https://auth.${cfg.proxy.domain}/logout";
        LD_ENABLE_OIDC = "True";
        OIDC_OP_AUTHORIZATION_ENDPOINT = "https://auth.${cfg.proxy.domain}/api/oidc/authorization";
        OIDC_OP_TOKEN_ENDPOINT = "https://auth.${cfg.proxy.domain}/api/oidc/token";
        OIDC_OP_USER_ENDPOINT = "https://auth.${cfg.proxy.domain}/api/oidc/userinfo";
        OIDC_OP_JWKS_ENDPOINT = "https://auth.${cfg.proxy.domain}/jwks.json";
      };
    };

    services = {
      postgresql = {
        ensureDatabases = [ cfg.database.name ];
        ensureUsers = [
          {
            name = cfg.database.user;
            ensureDBOwnership = true;
          }
        ];
      };

      traefik.dynamicConfigOptions.http = mkIf cfg.proxy.enable {
        routers.linkding = {
          rule = "Host(`links.${cfg.proxy.domain}`)";
          entryPoints = [ "websecure" ];
          service = "linkding";
          tls.certResolver = "letsencrypt";
        };
        services.linkding.loadBalancer = {
          servers = [ { url = "http://localhost:${toString ports.linkding}"; } ];
        };
      };
    };
  };
}
