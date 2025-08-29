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
in
{
  options.${namespace}.services.gatus = {
    enable = mkEnableOption "Gatus Uptime Monitor";
    domain = mkOpt types.str "yashgarg.dev" "Base domain for Gatus";
    host = mkOpt types.str "zenith" "Host name of the system";
    monitorPoints = mkOption {
      type =
        with types;
        listOf (submodule {
          options = {
            name = mkOption {
              type = str;
              description = "Display name of the monitored service";
            };
            group = mkOption {
              type = str;
              default = "internal";
              description = "Group name for the monitored service";
            };
            url = mkOption {
              type = str;
              description = "URL of the monitored service";
            };
          };
        });
      default = [ ];
      description = "List of services to monitor, each with a name and URL.";
    };
  };

  config = mkIf cfg.enable {
    age.secrets = {
      gatus-url.file = getSecret "gatus-ntfy" cfg.host;
    };

    services = {
      gatus = enabled // {
        environmentFile = config.age.secrets.gatus-url.path;
        settings = {
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
          endpoints = map (endpoint: {
            inherit (endpoint) name group url;
            ui = {
              hide-conditions = true;
              hide-hostname = true;
              hide-url = true;
            };
            interval = "10m";
            conditions = [
              "[STATUS] == 200"
              "[RESPONSE_TIME] < 500"
            ];
          }) cfg.monitorPoints;
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
