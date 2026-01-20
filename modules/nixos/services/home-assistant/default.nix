{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.home-assistant;
in
{
  options.${namespace}.services.home-assistant = {
    enable = mkEnableOption "Home Assistant: Home Automation System";
    domain = mkOpt types.str "ipx.ovh" "The domain name for home-assistant";
    port = mkOpt types.int ports.home-assistant "The port for home-assistant";
  };

  config = mkIf cfg.enable {
    services = {
      home-assistant = enabled // {
        openFirewall = true;
        package =
          (pkgs.home-assistant.override {
            extraPackages = py: with py; [ psycopg2 ];
          }).overrideAttrs
            (oldAttrs: {
              doInstallCheck = false;
            });
        config = {
          default_config = { };
          homeassistant = {
            external_url = "https://home.${cfg.domain}";
            temperature_unit = "C";
            time_zone = "Asia/Kolkata";
            unit_system = "metric";
          };
          http = {
            use_x_forwarded_for = true;
            server_port = cfg.port;
          };
          recorder.db_url = "postgresql://@/hass";
        };
      };

      postgresql = {
        ensureDatabases = [ "hass" ];
        ensureUsers = [
          {
            name = "hass";
            ensureDBOwnership = true;
          }
        ];
      };

      traefik.dynamicConfigOptions.http = {
        routers.home-assistant = {
          rule = "Host(`home.${cfg.domain}`)";
          entryPoints = [ "websecure" ];
          service = "home-assistant";
          tls.certResolver = "letsencrypt";
        };
        services.home-assistant.loadBalancer = {
          servers = [ { url = "http://localhost:${toString cfg.port}"; } ];
        };
      };
    };
  };
}
