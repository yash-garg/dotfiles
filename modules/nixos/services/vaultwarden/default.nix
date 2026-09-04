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
  cfg = srv.vaultwarden;

  authUrl = "https://auth.${cfg.domain}";
in
{
  options.${namespace}.services.vaultwarden = {
    enable = mkEnableOption "Vaultwarden: self-hosted Bitwarden server";
    domain = mkOpt types.str "ipx.ovh" "Base domain for vaultwarden";
    port = mkOpt types.int ports.vaultwarden "Port for the vaultwarden service";
    backup = {
      enable = mkEnableOption "Enable restic backup for Vaultwarden";
      url =
        mkOpt types.str "06a4a54ded73aeb04fb12c679a65ed78.r2.cloudflarestorage.com"
          "Restic repository URL";
    };

    smtp = {
      enable = mkEnableOption "SMTP email sending for Vaultwarden";
      host = mkOpt types.str "" "SMTP server host";
      port = mkOpt types.port 587 "SMTP server port";
      security = mkOpt (types.enum [ "starttls" "force_tls" "off" ]) "starttls" "SMTP transport security";
      from = mkOpt types.str "" "Email address to send from";
      fromName = mkOpt types.str "Vaultwarden" "Display name to send from";
      username = mkOpt types.str "" "SMTP auth username";
      authMechanism = mkOpt types.str "Plain" "SMTP auth mechanism (Plain, Login, Xoauth2)";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.vaultwarden-env = {
      sopsFile = lib.dots.get-file "secrets/vaultwarden.env";
      format = "dotenv";
    };

    services.vaultwarden = enabled // {
      dbBackend = "postgresql";
      configurePostgres = true;
      environmentFile = config.sops.secrets.vaultwarden-env.path;
      config = {
        DOMAIN = "https://pass.${cfg.domain}";
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = cfg.port;
        SIGNUPS_ALLOWED = false;
        INVITATIONS_ALLOWED = true;

        # OIDC via Authelia as the only login method.
        SSO_ENABLED = true;
        SSO_ONLY = true;
        SSO_AUTHORITY = authUrl;
        SSO_CLIENT_ID = "vaultwarden";
        SSO_SCOPES = "openid email profile offline_access";
        SSO_PKCE = true;
      } // optionalAttrs cfg.smtp.enable {
        SMTP_HOST = cfg.smtp.host;
        SMTP_PORT = cfg.smtp.port;
        SMTP_SECURITY = cfg.smtp.security;
        SMTP_FROM = cfg.smtp.from;
        SMTP_FROM_NAME = cfg.smtp.fromName;
        SMTP_USERNAME = cfg.smtp.username;
        SMTP_AUTH_MECHANISM = cfg.smtp.authMechanism;
        # SMTP_PASSWORD is set via secrets/vaultwarden.env (SMTP_PASSWORD=...).
      };
    };

    services.restic.backups.vaultwarden = mkIf (cfg.backup.enable && srv.restic.enable) (
      srv.restic.mkBackup "vaultwarden" {
        paths = [ "/var/lib/vaultwarden" ];
        repository = "s3:${cfg.backup.url}/vaultwarden";
      }
    );

    dots.services.caddy.services.pass = {
      inherit (cfg) domain;
      upstream = "localhost:${toString cfg.port}";
      auth = false;
    };
  };
}
