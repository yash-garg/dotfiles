{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.authelia;
in
{
  options.${namespace}.services.authelia = {
    enable = mkEnableOption "Enable Authelia OIDC";
    domain = mkOpt types.str "yashgarg.dev" "Base domain for Authelia";
    host = mkOpt types.str "zenith" "Host for Authelia";
  };

  config = mkIf cfg.enable {
    sops.secrets =
      let
        secretAttrs = {
          sopsFile = snowfall.fs.get-file "secrets/authelia.yaml";
          owner = config.services.authelia.instances.main.user;
          inherit (config.services.authelia.instances.main) group;
          mode = "0600";
        };
      in
      {
        jwt-secret = secretAttrs;
        session-secret = secretAttrs;
        storage-secret = secretAttrs;
        hmac-secret = secretAttrs;
        ldap-secret = secretAttrs;
        notifier-settings = secretAttrs;
        user-settings = secretAttrs;
        oidc-key = secretAttrs // {
          sopsFile = snowfall.fs.get-file "secrets/oidc.key";
          format = "binary";
        };
      };

    services = {
      authelia = {
        instances.main = enabled // {
          environmentVariables = {
            AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.sops.secrets.ldap-secret.path;
          };
          secrets = {
            jwtSecretFile = config.sops.secrets.jwt-secret.path;
            sessionSecretFile = config.sops.secrets.session-secret.path;
            storageEncryptionKeyFile = config.sops.secrets.storage-secret.path;
            oidcIssuerPrivateKeyFile = config.sops.secrets.oidc-key.path;
            oidcHmacSecretFile = config.sops.secrets.hmac-secret.path;
          };
          settings = import ./settings.nix { inherit lib config namespace; };
          settingsFiles = [ config.sops.secrets.notifier-settings.path ];
        };
      };

      traefik.dynamicConfigOptions.http = {
        routers.authelia = {
          rule = "Host(`auth.${cfg.domain}`)";
          entryPoints = [ "websecure" ];
          service = "authelia";
          tls.certResolver = "letsencrypt";
        };
        services.authelia.loadBalancer = {
          servers = [ { url = "http://localhost:9091"; } ];
        };
      };
    };
  };
}
