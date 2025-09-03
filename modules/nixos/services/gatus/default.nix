{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.gatus;
  endpoints = builtins.fromJSON (builtins.readFile cfg.configFile);
in
{
  options.${namespace}.services.gatus = {
    enable = mkEnableOption "Gatus Uptime Monitor";
    domain = mkOpt types.str "yashgarg.dev" "Base domain for Gatus";
    configFile =
      mkOpt (types.nullOr types.path) null
        "Path to custom endpoints configuration file (JSON format)";
  };

  config = mkIf cfg.enable {
    sops.secrets.gatus-env = {
      sopsFile = snowfall.fs.get-file "secrets/gatus.env";
      format = "dotenv";
    };

    services = {
      gatus = enabled // {
        environmentFile = config.sops.secrets.gatus-env.path;
        settings = recursiveUpdate endpoints {
          alerting.ntfy = {
            topic = "$GATUS_TOPIC";
            click = "https://status.${cfg.domain}";
            default-alert = {
              description = "Gatus health check";
              send-on-resolved = true;
              failure-threshold = 5;
              success-threshold = 2;
            };
          };
          web.port = ports.gatus;
          connectivity.checker = {
            target = "1.1.1.1:53";
            interval = "60s";
          };
          ui = {
            title = "Homelab Status | Yash Garg";
            description = "Monitoring for My Services";
            header = "Yash's Homelab Status";
            link = "https://status.${cfg.domain}";
            dark-mode = true;
          };
        };
      };

      traefik.dynamicConfigOptions.http = {
        routers.gatus = {
          rule = "Host(`status.${cfg.domain}`)";
          entryPoints = [ "websecure" ];
          service = "gatus";
          tls.certResolver = "letsencrypt";
        };

        services.gatus.loadBalancer = {
          servers = [ { url = "http://localhost:${toString ports.gatus}"; } ];
        };
      };
    };
  };
}
