{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  srv = config.${namespace}.services;
  cfg = srv.actual-budget;
in
{
  options.${namespace}.services.actual-budget = {
    enable = mkEnableOption "Actual Budget Service";
    domain = mkOpt types.str "ipx.ovh" "The domain name for the actual budget service";
    backup = {
      enable = mkEnableOption "Enable restic backup for Actual Budget";
      url =
        mkOpt types.str "06a4a54ded73aeb04fb12c679a65ed78.r2.cloudflarestorage.com"
          "Restic repository URL";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.actual-env = {
      sopsFile = snowfall.fs.get-file "secrets/actual.env";
      format = "dotenv";
    };

    services = {
      actual = enabled // {
        openFirewall = true;
        settings = {
          port = ports.actual-budget;
          allowedLoginMethods = [ "openid" ];
          enforceOpenId = true;
          loginMethod = "openid";
          openId = {
            discoveryURL = "https://auth.${cfg.domain}";
            server_hostname = "https://money.${cfg.domain}";
            authMethod = "openid";
          };
        };
      };

      restic.backups.actual-budget = mkIf (cfg.backup.enable && srv.restic.enable) (
        srv.restic.mkBackup "actual-budget" {
          paths = [
            config.services.actual.settings.serverFiles
            config.services.actual.settings.userFiles
          ];
          repository = "s3:${cfg.backup.url}/actual-budget";
        }
      );

      traefik.dynamic.files.actual-budget.settings.http = {
        routers.actual = {
          rule = "Host(`money.${cfg.domain}`)";
          entryPoints = [ "websecure" ];
          middlewares = [ "crowdsec" ];
          service = "actual";
          tls.certResolver = "letsencrypt";
        };
        services.actual.loadBalancer = {
          servers = [ { url = "http://localhost:${toString ports.actual-budget}"; } ];
        };
      };
    };

    systemd.services.actual.serviceConfig.EnvironmentFile = [
      config.sops.secrets.actual-env.path
    ];
  };
}
