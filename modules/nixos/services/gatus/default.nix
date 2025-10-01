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
        conditions = [
          "[STATUS] == 200"
          "[RESPONSE_TIME] < 1000"
        ]
        ++ endpoint.extraConditions;
      in
      {
        inherit (endpoint) name url interval;
        inherit conditions;
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
