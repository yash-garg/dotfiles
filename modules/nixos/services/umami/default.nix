{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.umami;
in
{
  options.${namespace}.services.umami = {
    enable = mkEnableOption "Enable umami analytics";
    appSecretFile =
      mkOpt types.path null
        "Path to a file containing the secret key for the umami server";
    baseUrl = mkOpt types.str "yashgarg.dev" "Base URL for the umami server";
    port = mkOpt types.int ports.umami "The port for umami";
    openFirewall = mkBoolOpt true "Open firewall for umami";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    services = {
      umami = enabled // {
        createPostgresqlDatabase = true;
        settings = {
          APP_SECRET_FILE = cfg.appSecretFile;
          DATABASE_TYPE = "postgresql";
          DISABLE_TELEMETRY = true;
          DISABLE_UPDATES = true;
          HOSTNAME = "0.0.0.0";
          PORT = cfg.port;
        };
      };

      traefik.dynamicConfigOptions.http = {
        routers.umami = {
          rule = "Host(`analytics.${cfg.baseUrl}`)";
          entryPoints = [ "websecure" ];
          service = "umami";
          middlewares = [ "crowdsec" ];
          tls.certResolver = "letsencrypt";
        };
        services.umami.loadBalancer = {
          servers = [ { url = "http://localhost:${toString cfg.port}"; } ];
        };
      };
    };
  };
}
