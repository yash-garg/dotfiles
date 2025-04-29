{
  config,
  namespace,
  ...
}:
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

  authentication_backend = {
    password_reset.disable = true;
    refresh_interval = "5m";
    file = {
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

  storage.local.path = "/var/lib/authelia-main/authelia.sqlite";

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
