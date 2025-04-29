{
  config,
  namespace,
  ...
}:
let
  inherit (config.${namespace}.services.authelia) domain;
in
{
  default_redirection_url = "https://auth.${domain}/";
  default_2fa_method = "webauthn";
  server.disable_healthcheck = true;
  theme = "auto";
  totp.disable = true;

  access_control = {
    default_policy = "deny";
    rules = [
      {
        domain = "auth.${domain}";
        policy = "two_factor";
        networks = "127.0.0.1";
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

  identity_providers = {
    oidc = {
      enable_client_debug_messages = false;
      enforce_pkce = "always";
      lifespans = {
        access_token = "30m";
        authorize_code = "1m";
        id_token = "30m";
        refresh_token = "90m";
      };
      cors = {
        endpoints = [
          "authorization"
          "token"
          "revocation"
          "introspection"
          "userinfo"
        ];
        allowed_origins = [ "https://auth.${domain}" ];
        allowed_origins_from_client_redirect_uris = false;
      };
      claims_policies.default = {
        id_token = [
          "email"
          "email_verified"
          "alt_emails"
          "preferred_username"
          "name"
        ];
      };
      clients = [
        {
          claims_policy = "default";
          client_id = "cloudflare";
          client_name = "Cloudflare Access";
          client_secret = "$pbkdf2-sha512$310000$GNNb7iBfxmGChaMxO00vqw$HfymqwZWXPowLE5VXoW2Rx5eSfB7XBscVvscrf05qdlvrNwFL/AcuAmHgIsytJCI7Hevmu.guT6ytxr.VIKcrA";
          public = false;
          authorization_policy = "two_factor";
          consent_mode = "pre-configured";
          pre_configured_consent_duration = "6M";
          redirect_uris = [
            "https://yashg.cloudflareaccess.com/cdn-cgi/access/callback"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          userinfo_signed_response_alg = "RS256";
        }
      ];
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

  session = {
    name = "authelia_session";
    domain = "auth.${domain}";
    same_site = "strict";
    expiration = "30m";
    inactivity = "15m";
    remember_me = "30m";
  };

  storage.local.path = "/var/lib/authelia-main/authelia.sqlite";

  telemetry.metrics = {
    enabled = true;
  };

  webauthn = {
    disable = false;
    enable_passkey_login = true;
    display_name = "Authelia";
    attestation_conveyance_preference = "direct";
    selection_criteria.user_verification = "required";
    timeout = "60s";
  };
}
