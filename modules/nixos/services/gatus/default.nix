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
  endpointType = types.submodule (
    { name, ... }:
    {
      options = {
        name = mkOpt types.nonEmptyStr name "Display name for the endpoint";
        group = mkOpt types.str "" "Optional group for organizing endpoints";
        url = mkOpt types.nonEmptyStr "" "URL to monitor";
        interval = mkOpt types.nonEmptyStr "10m" "How often to check the endpoint";
        extraConditions =
          mkOpt (types.listOf types.nonEmptyStr) [ ]
            "Additional conditions beyond the defaults";
      };
    }
  );
  endpointsConfig = {
    endpoints = mapAttrsToList (
      _: endpoint:
      let
        # Determine if this is a TCP/UDP endpoint based on URL prefix
        isTcpUdp = (hasPrefix "tcp://" endpoint.url) || (hasPrefix "udp://" endpoint.url);

        # Use different default conditions for TCP/UDP vs HTTP endpoints
        defaultConditions =
          if isTcpUdp then
            [ "[CONNECTED] == true" ]
          else
            [
              "[STATUS] == 200"
              "[RESPONSE_TIME] < 1000"
            ];

        conditions = defaultConditions ++ endpoint.extraConditions;
      in
      {
        inherit (endpoint) name url interval;
        inherit conditions;
        alerts = [
          { type = "discord"; }
          { type = "ntfy"; }
        ];
        ui = {
          hide-conditions = true;
          hide-hostname = true;
          hide-url = true;
        };
      }
      // (optionalAttrs (endpoint.group != "") { inherit (endpoint) group; })
    ) cfg.endpoints;
  };
in
{
  options.${namespace}.services.gatus = {
    enable = mkEnableOption "Gatus Uptime Monitor";
    domain = mkOpt types.str "yashgarg.dev" "Base domain for Gatus";
    endpoints = mkOpt (types.attrsOf endpointType) { } "Endpoints to monitor";
    alerting = {
      failureThreshold = mkOpt types.int 1 "Number of consecutive failures before alerting";
      successThreshold = mkOpt types.int 2 "Number of consecutive successes before resolving";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.gatus-env = {
      sopsFile = snowfall.fs.get-file "secrets/gatus.env";
      format = "dotenv";
    };

    services = {
      gatus = enabled // {
        environmentFile = config.sops.secrets.gatus-env.path;
        settings = recursiveUpdate endpointsConfig {
          alerting = {
            discord = {
              webhook-url = "\${GATUS_WEBHOOK_URL}";
            };
            ntfy = {
              topic = "\${GATUS_TOPIC}";
              url = "https://ntfy.sh";
              click = "https://status.${cfg.domain}";
              default-alert = {
                description = "Gatus Health Check";
                send-on-resolved = true;
                failure-threshold = cfg.alerting.failureThreshold;
                success-threshold = cfg.alerting.successThreshold;
              };
            };
          };
          metrics = true;
          storage = {
            type = "postgres";
            path = "postgresql:///gatus?host=/run/postgresql";
            maximum-number-of-results = 1000;
            maximum-number-of-events = 1000;
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
            link = "https://${cfg.domain}";
            logo = "https://${cfg.domain}/img/logo.png";
            dark-mode = true;
          };
        };
      };

      postgresql = {
        ensureDatabases = [ "gatus" ];
        ensureUsers = [
          {
            name = "gatus";
            ensureDBOwnership = true;
          }
        ];
      };

      prometheus.scrapeConfigs = [
        {
          job_name = "gatus";
          static_configs = [
            { targets = [ "localhost:${toString ports.gatus}" ]; }
          ];
        }
      ];

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
