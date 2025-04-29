{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  inherit (config.${namespace}.services.authelia) domain;
in
{
  default_2fa_method = "webauthn";
  theme = "auto";
  totp.disable = true;

  access_control = {
    default_policy = "deny";
    networks = [
      {
        name = "local";
        networks = [
          "127.0.0.0/8"
        ];
      }
    ];
    rules = [
      {
        domain = "auth.${domain}";
        policy = "one_factor";
      }
      {
        domain = "*.${domain}";
        policy = "two_factor";
      }
    ];
  };

  authentication_backend =
    let
      lldapEnabled = config.${namespace}.services.lldap.enable;
    in
    {
      password_reset.disable = true;
      refresh_interval = "5m";
      file = mkIf (!lldapEnabled) {
        inherit (config.age.secrets.usersFile) path;
        password = {
          algorithm = "argon2id";
          iterations = 1;
          key_length = 32;
          salt_length = 16;
          memory = 1024;
          parallelism = 8;
        };
      };
      ldap = mkIf lldapEnabled {
        address = "ldap://localhost:3890";
        base_dn = "dc=yashgarg,dc=dev";
        users_filter = "(&({username_attribute}={input})(objectClass=person))";
        groups_filter = "(member={dn})";
        user = "uid=admin,ou=people,dc=yashgarg,dc=dev";
      };
    };

  log = {
    level = "debug";
    format = "json";
    file_path = "/tmp/authelia.log";
    keep_stdout = true;
  };

  ntp = {
    address = "time.cloudflare.com:123";
    disable_startup_check = false;
    disable_failure = true;
    version = 4;
    max_desync = "3s";
  };

  regulation = {
    max_retries = "5";
    find_time = "2m";
    ban_time = "5m";
  };

  storage.postgres = {
    address = "unix:///run/postgresql";
    database = "authelia-main";
    username = "authelia-main";
    password = "authelia-main";
  };

  server = {
    disable_healthcheck = true;
    endpoints.authz.forward-auth.implementation = "ForwardAuth";
  };

  session.cookies = [
    {
      inherit domain;
      authelia_url = "https://auth.${domain}";
      default_redirection_url = "https://${domain}/";
    }
  ];

  telemetry.metrics = {
    enabled = true;
  };

  webauthn = {
    disable = false;
    enable_passkey_login = true;
    display_name = "Authelia";
    attestation_conveyance_preference = "direct";
    selection_criteria.user_verification = "preferred";
    timeout = "60s";
  };
}
