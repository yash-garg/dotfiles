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

    networking.firewall.allowedTCPPorts = [ ports.miniflux ];
    services = {
      miniflux = enabled // {
        adminCredentialsFile = config.sops.secrets.miniflux-env.path;
        createDatabaseLocally = true;
        config = {
          BASE_URL = "https://rss.${cfg.proxy.domain}/";
          HTTPS = 1;
          LISTEN_ADDR = "[::]:${toString ports.miniflux}";
          LOG_DATE_TIME = 1;
          LOG_FORMAT = "json";
          METRICS_ALLOWED_NETWORKS = "0.0.0.0/0,::/0";
          METRICS_COLLECTOR = 1;
          DISABLE_LOCAL_AUTH = 1;
          AUTH_PROXY_HEADER = "Remote-User";
          AUTH_PROXY_USER_CREATION = 1;
          TRUSTED_REVERSE_PROXY_NETWORKS = "127.0.0.1/32,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,100.64.0.0/10";
        };
      };

      prometheus.scrapeConfigs = mkIf (config.services.miniflux.config.METRICS_COLLECTOR or 0 == 1) [
        {
          job_name = "miniflux";
          static_configs = [ { targets = [ config.services.miniflux.config.LISTEN_ADDR ]; } ];
        }
      ];

    };

    dots.services.caddy.services.rss = mkIf cfg.proxy.enable {
      inherit (cfg.proxy) domain;
      upstream = config.services.miniflux.config.LISTEN_ADDR;
    };
  };
}
