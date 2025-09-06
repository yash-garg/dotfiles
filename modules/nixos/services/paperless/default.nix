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
    proxy = {
      enable = mkEnableOption "Enable traefik proxy for Paperless";
      domain = mkOpt types.str "ipx.ovh" "The domain name for the paperless service";
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
        configureTika = true;
        database.createLocally = true;
        environmentFile = config.sops.secrets.paperless-env.path;
        port = ports.paperless-ngx;
        settings = {
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
  };
}
