{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.miniflux;
in
{
  options.${namespace}.services.miniflux = {
    enable = mkEnableOption "Miniflux: RSS Reader";
    proxy = {
      enable = mkEnableOption "Enable traefik proxy for Miniflux";
      domain = mkOpt types.str "ipx.ovh" "The domain name for the miniflux service";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.miniflux-env = {
      sopsFile = snowfall.fs.get-file "secrets/miniflux.env";
      format = "dotenv";
    };

    services = {
      miniflux = enabled // {
        adminCredentialsFile = config.sops.secrets.miniflux-env.path;
        createDatabaseLocally = true;
        config = {
          BASE_URL = "https://rss.${cfg.proxy.domain}/";
          HTTPS = 1;
          LISTEN_ADDR = "0.0.0.0:${toString ports.miniflux}";
          LOG_DATE_TIME = 1;
          LOG_FORMAT = "json";
          METRICS_ALLOWED_NETWORKS = "0.0.0.0/0";
          METRICS_COLLECTOR = 1;
          DISABLE_LOCAL_AUTH = 1;
          OAUTH2_USER_CREATION = 1;
          OAUTH2_PROVIDER = "oidc";
          OAUTH2_OIDC_PROVIDER_NAME = "Authelia";
          OAUTH2_REDIRECT_URL = "https://rss.${cfg.proxy.domain}/oauth2/oidc/callback";
          OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://auth.${cfg.proxy.domain}";
        };
      };

      prometheus.scrapeConfigs = mkIf (config.services.miniflux.config.METRICS_COLLECTOR or 0 == 1) [
        {
          job_name = "miniflux";
          static_configs = [ { targets = [ config.services.miniflux.config.LISTEN_ADDR ]; } ];
        }
      ];

      traefik.dynamicConfigOptions.http = mkIf cfg.proxy.enable {
        routers.miniflux = {
          rule = "Host(`rss.${cfg.proxy.domain}`)";
          entryPoints = [ "websecure" ];
          service = "miniflux";
          tls.certResolver = "letsencrypt";
        };
        services.miniflux.loadBalancer = {
          servers = [ { url = "http://${config.services.miniflux.config.LISTEN_ADDR}"; } ];
        };
      };
    };
  };
}
