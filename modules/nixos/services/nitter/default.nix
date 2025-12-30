{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.nitter;
in
{
  options.${namespace}.services.nitter = {
    enable = mkEnableOption "nitter: alternative Twitter front-end";
    domain = mkOpt types.str "ipx.ovh" "The domain to serve nitter on";
    port = mkOpt types.int ports.nitter "The port for nitter";
  };

  config = mkIf cfg.enable {
    sops.secrets.sessions-secret = {
      sopsFile = snowfall.fs.get-file "secrets/nitter.yaml";
      format = "binary";
    };

    services = {
      nitter = enabled // {
        openFirewall = true;
        cache.redisPort = ports.redis;
        redisCreateLocally = true;
        preferences = {
          autoplayGifs = false;
        };
        server = {
          inherit (cfg) port;
          https = true;
          title = "X - Nitter";
        };
        sessionsFile = config.sops.secrets.sessions-secret.path;
      };

      traefik.dynamicConfigOptions.http = {
        routers.nitter = {
          rule = "Host(`x.${cfg.domain}`)";
          entryPoints = [ "websecure" ];
          middlewares = [ "crowdsec" ];
          service = "nitter";
          tls.certResolver = "letsencrypt";
        };

        services.nitter.loadBalancer = {
          servers = [ { url = "http://localhost:${toString cfg.port}"; } ];
        };
      };
    };
  };
}
