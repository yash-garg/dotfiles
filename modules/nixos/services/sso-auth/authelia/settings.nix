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
        allowed_origins_from_client_redirect_uris = true;
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
          client_id = "cloudflare";
          client_name = "Cloudflare Access";
          client_secret = "$pbkdf2-sha512$310000$GNNb7iBfxmGChaMxO00vqw$HfymqwZWXPowLE5VXoW2Rx5eSfB7XBscVvscrf05qdlvrNwFL/AcuAmHgIsytJCI7Hevmu.guT6ytxr.VIKcrA";
          public = false;
          authorization_policy = "two_factor";
          claims_policy = "default";
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
          token_endpoint_auth_method = "client_secret_basic";
        }
        {
          client_id = "actual-budget";
          client_name = "Actual Budget";
          client_secret = "$pbkdf2-sha512$310000$iWomIaFYWHHBwj3ILVzL.Q$l9rRfes89uaXIGQnSZqtlLsAa8zMkjHWvUL39mnjHXBq.bokav5Z.dc3.mcUZxkW.5M64InDQZ5eg/81HWlETA";
          public = false;
          authorization_policy = "one_factor";
          grant_types = [
            "authorization_code"
          ];
          redirect_uris = [
            "https://actual.${domain}/openid/callback"
            "https://budget.${domain}/openid/callback"
          ];
          scopes = [
            "openid"
            "profile"
            "groups"
            "email"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
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

  totp = {
    disable = false;
    issuer = domain;
    disable_reuse_security_policy = true;
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
