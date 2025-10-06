{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.mealie;
in
{
  options.${namespace}.services.mealie = {
    enable = mkEnableOption "Mealie: Recipe Manager";
    domain = mkOpt types.str "ipx.ovh" "Domain name for mealie";
    port = mkOpt types.int ports.mealie "Port to listen on";
  };

  config = mkIf cfg.enable {
    sops.secrets.mealie-env = {
      sopsFile = snowfall.fs.get-file "secrets/mealie.env";
      format = "dotenv";
    };

    services = {
      mealie = enabled // {
        inherit (cfg) port;
        credentialsFile = config.sops.secrets.mealie-env.path;
        database.createLocally = true;
        settings = {
          ALLOW_PASSWORD_LOGIN = false;
          ALLOW_SIGNUP = false;
          API_DOCS = false;
          OIDC_AUTH_ENABLED = true;
          OIDC_SIGNUP_ENABLED = true;
          OIDC_CONFIGURATION_URL = "https://auth.${cfg.domain}/.well-known/openid-configuration";
          OIDC_AUTO_REDIRECT = true;
          OIDC_PROVIDER_NAME = "Authelia";
          OIDC_ADMIN_GROUP = "mealie-admins";
          OIDC_USER_GROUP = "mealie-users";
        };
      };

      traefik.dynamicConfigOptions.http = {
        routers.mealie = {
          rule = "Host(`meals.${cfg.domain}`)";
          entryPoints = [ "websecure" ];
          service = "mealie";
          tls.certResolver = "letsencrypt";
        };
        services.mealie.loadBalancer = {
          servers = [ { url = "http://localhost:${toString config.services.mealie.port}"; } ];
        };
      };
    };
  };
}
