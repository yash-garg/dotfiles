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
  imports = [ ./settings.nix ];

  options.${namespace}.services.authelia = {
    enable = mkEnableOption "Enable Authelia OIDC";
    domain = mkOpt types.str "yashgarg.dev" "Base domain for Authelia";
    host = mkOpt types.str "zenith" "Host for Authelia";
  };

  config = mkIf cfg.enable {
    age.secrets =
      let
        hostPath = "${cfg.host}/authelia";
        secretAttrs = {
          owner = config.services.authelia.instances.main.user;
          inherit (config.services.authelia.instances.main) group;
          mode = "0600";
        };
      in
      {
        jwtSecret = secretAttrs // {
          file = getSecret "jwt" hostPath;
        };
        sessionSecret = secretAttrs // {
          file = getSecret "session" hostPath;
        };
        storageEncryptionKey = secretAttrs // {
          file = getSecret "storage" hostPath;
        };
        usersFile = secretAttrs // {
          file = getSecret "users.yml" hostPath;
        };
        oidcIssuerPrivateKey = secretAttrs // {
          file = getSecret "oidc" hostPath;
        };
        oidcHmacSecretKey = secretAttrs // {
          file = getSecret "hmac" hostPath;
        };
        notifierSettings = secretAttrs // {
          file = getSecret "notifier.yml" hostPath;
        };
        ldapPassword = secretAttrs // {
          file = getSecret "ldap" hostPath;
        };
      };

    services = {
      authelia = {
        instances.main = enabled // {
          environmentVariables = {
            AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.age.secrets.ldapPassword.path;
          };
          secrets = {
            jwtSecretFile = config.age.secrets.jwtSecret.path;
            sessionSecretFile = config.age.secrets.sessionSecret.path;
            storageEncryptionKeyFile = config.age.secrets.storageEncryptionKey.path;
            oidcIssuerPrivateKeyFile = config.age.secrets.oidcIssuerPrivateKey.path;
            oidcHmacSecretFile = config.age.secrets.oidcHmacSecretKey.path;
          };
          settingsFiles = [ config.age.secrets.notifierSettings.path ];
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
