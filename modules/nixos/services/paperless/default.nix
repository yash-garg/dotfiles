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
  cfg = srv.paperless;
in
{
  options.${namespace}.services.paperless = {
    enable = mkEnableOption "Paperless: Document Management System";
    dataDir = mkOpt types.str "/var/lib/paperless" "The data directory for paperless";
    mediaDir = mkOpt types.str "/var/lib/paperless/storage" "The media directory for paperless";
    proxy = {
      enable = mkEnableOption "Enable traefik proxy for Paperless";
      domain = mkOpt types.str "ipx.ovh" "The domain name for the paperless service";
    };
    user = mkOpt types.str "paperless" "The user for paperless";
    group = mkOpt types.str "paperless" "The group for paperless";
    backup = {
      enable = mkEnableOption "Enable restic backup for Paperless";
      url =
        mkOpt types.str "a69e81e6342baaeed47710799b04477a.r2.cloudflarestorage.com"
          "Restic repository URL";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.paperless-env = {
      sopsFile = lib.snowfall.fs.get-file "secrets/paperless.env";
      format = "dotenv";
      owner = config.services.paperless.user;
    };

    services = {
      paperless = enabled // {
        inherit (cfg)
          dataDir
          mediaDir
          user
          ;
        address = "0.0.0.0";
        configureTika = false;
        consumptionDirIsPublic = true;
        database.createLocally = true;
        environmentFile = config.sops.secrets.paperless-env.path;
        port = ports.paperless-ngx;
        settings = {
          PAPERLESS_FILENAME_FORMAT = "{{ created }}-{{ correspondent }}-{{ title }}";
          PAPERLESS_OCR_LANGUAGE = "eng";
          PAPERLESS_TIME_ZONE = "Asia/Kolkata";
          PAPERLESS_DISABLE_REGULAR_LOGIN = true;
          PAPERLESS_URL = "https://paperless.${cfg.proxy.domain}";
          PAPERLESS_REDIRECT_LOGIN_TO_SSO = false;
          PAPERLESS_OCR_SKIP_ARCHIVE_FILE = "always";
          PAPERLESS_WEBHOOKS_ALLOWED_SCHEMES = "https";
          PAPERLESS_ENABLE_HTTP_REMOTE_USER = true;
          PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME = "HTTP_REMOTE_USER";
          PAPERLESS_LOGOUT_REDIRECT_URL = "https://auth.${cfg.proxy.domain}/logout";
        };
      };

      restic.backups.paperless-ngx = mkIf (cfg.backup.enable && srv.restic.enable) (
        srv.restic.mkBackup "paperless-ngx" {
          environmentFile = config.sops.secrets.paperless-env.path;
          paths = [ cfg.mediaDir ];
          repository = "s3:${cfg.backup.url}/paperless-ngx";
          timerConfig.OnCalendar = "weekly";
        }
      );

      traefik.dynamic.files.paperless.settings.http = mkIf cfg.proxy.enable {
        routers.paperless = {
          rule = "Host(`paperless.${cfg.proxy.domain}`)";
          entryPoints = [ "websecure" ];
          middlewares = [
            "auth"
          ];
          service = "paperless";
          tls.certResolver = "letsencrypt";
        };
        services.paperless.loadBalancer = {
          servers = [ { url = "http://localhost:${toString ports.paperless-ngx}"; } ];
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0775 ${cfg.user} ${cfg.group} -"
      "d ${cfg.mediaDir} 0775 ${cfg.user} ${cfg.group} -"
    ];
  };
}
