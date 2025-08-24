{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.actual-budget;
in
{
  options.${namespace}.services.actual-budget = {
    enable = mkEnableOption "Actual Budget Service";

    domain = mkOption {
      type = types.str;
      default = "ipx.ovh";
    };

    host = mkOption {
      type = types.str;
      default = "zenith";
    };

    port = mkOption {
      type = types.int;
      default = 3000;
    };
  };

  config = mkIf cfg.enable {
    age.secrets = {
      actual-env.file = getSecret "actual.env" cfg.host;
    };

    services = {
      actual = enabled // {
        openFirewall = true;
        settings = {
          inherit (cfg) port;
          allowedLoginMethods = [ "openid" ];
          enforceOpenId = true;
          loginMethod = "openid";
          openId = {
            discoveryURL = "https://auth.${cfg.domain}";
            client_id = "actual-budget";
            server_hostname = "https://money.${cfg.domain}";
            authMethod = "openid";
          };
        };
      };

      traefik.dynamicConfigOptions.http = {
        routers.actual = {
          rule = "Host(`money.${cfg.domain}`)";
          entryPoints = [ "websecure" ];
          service = "actual";
          tls.certResolver = "letsencrypt";
        };

        services.actual.loadBalancer = {
          servers = [ { url = "http://localhost:${toString cfg.port}"; } ];
        };
      };
    };

    systemd.services.actual.serviceConfig.EnvironmentFile = [
      config.age.secrets.actual-env.path
    ];
  };
}
