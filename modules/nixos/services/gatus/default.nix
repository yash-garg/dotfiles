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
        maxResponseTimeMs =
          mkOpt types.int 1000
            "Max response time in ms for HTTP endpoints; use higher values for external/slow sites";
        extraConditions = mkOpt (types.listOf types.nonEmptyStr) [
          "[STATUS] == 200"
        ] "Force conditions to be true";
      };
    }
  );
  endpointsConfig = {
    endpoints = mapAttrsToList (
      _: endpoint:
      let
        # Determine if this is a TCP/UDP endpoint based on URL prefix
        isTcpUdp = (hasPrefix "tcp://" endpoint.url) || (hasPrefix "udp://" endpoint.url);

        # Use different conditions for TCP/UDP vs HTTP endpoints
        conditions =
          if isTcpUdp then
            [ "[CONNECTED] == true" ]
          else
            endpoint.extraConditions ++ [ "[RESPONSE_TIME] < ${toString endpoint.maxResponseTimeMs}" ];
      in
      {
        inherit (endpoint) name url interval;
        inherit conditions;
        alerts = [
          {
            type = "pushover";
            enabled = true;
            send-on-resolved = true;
            failure-threshold = cfg.alerting.failureThreshold;
            success-threshold = cfg.alerting.successThreshold;
          }
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
      failureThreshold = mkOpt types.int 2 "Number of consecutive failures before alerting";
      successThreshold = mkOpt types.int 2 "Number of consecutive successes before resolving";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.gatus-env = {
      sopsFile = lib.dots.get-file "secrets/gatus.env";
      format = "dotenv";
    };

    services = {
      gatus = enabled // {
        environmentFile = config.sops.secrets.gatus-env.path;
        settings = recursiveUpdate endpointsConfig {
          alerting.pushover = {
            application-token = "\${PUSHOVER_API_TOKEN}";
            user-key = "\${PUSHOVER_USER_KEY}";
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
            default-sort-by = "group";
            header = "Yash's Homelab Status";
            link = "https://${cfg.domain}";
            logo = "https://${cfg.domain}/android-chrome-192x192.png";
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

    };

    dots.services.caddy.services.status = {
      inherit (cfg) domain;
      upstream = "localhost:${toString ports.gatus}";
      auth = false;
    };
  };
}
