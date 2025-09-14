{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.paperless;
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
          PAPERLESS_REDIRECT_LOGIN_TO_SSO = true;
          PAPERLESS_OCR_SKIP_ARCHIVE_FILE = "always";
          PAPERLESS_WEBHOOKS_ALLOWED_SCHEMES = "https";
        };
      };

      traefik.dynamicConfigOptions.http = mkIf cfg.proxy.enable {
        routers.paperless = {
          rule = "Host(`paperless.${cfg.proxy.domain}`)";
          entryPoints = [ "websecure" ];
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
