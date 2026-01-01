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
  base_dn = "dc=${concatStringsSep ",dc=" (splitString "." domain)}";
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
        policy = "two_factor";
      }
      {
        domain = "books.${domain}";
        policy = "bypass";
        resources = [ "^/opds/" ];
      }
      {
        domain = "books.${domain}";
        policy = "one_factor";
        subject = [
          "group:internal"
          "group:books-users"
        ];
      }
      {
        domain = "links.${domain}";
        policy = "bypass";
        resources = [ "^/api/" ];
      }
      {
        domain = "paperless.${domain}";
        policy = "bypass";
        resources = [
          "^/api/"
          "^/share/"
        ];
      }
      {
        domain = "rss.${domain}";
        policy = "bypass";
        resources = [ "^/fever/" ];
      }
      {
        domain = "*.${domain}";
        policy = "one_factor";
        subject = [ "group:internal" ];
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
        inherit (config.sops.secrets.user-settings) path;
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
        inherit base_dn;
        address = "ldap://localhost:3890";
        users_filter = "(&({username_attribute}={input})(objectClass=person))";
        groups_filter = "(member={dn})";
        user = "uid=admin,ou=people,${base_dn}";
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
      claims_policies = {
        default.id_token = [
          "email"
          "email_verified"
          "alt_emails"
          "preferred_username"
          "name"
        ];
        grafana.id_token = [
          "email"
          "name"
          "groups"
          "preferred_username"
        ];
      };
      authorization_policies = {
        internal_one_factor = {
          default_policy = "deny";
          rules = [
            {
              policy = "one_factor";
              subject = [ "group:internal" ];
            }
          ];
        };
        mealie_access = {
          default_policy = "deny";
          rules = [
            {
              policy = "one_factor";
              subject = [
                "group:internal"
                "group:mealie-admins"
                "group:mealie-users"
              ];
            }
          ];
        };
        jellyfin_access = {
          default_policy = "deny";
          rules = [
            {
              policy = "one_factor";
              subject = [
                "group:internal"
                "group:jellyfin-admins"
                "group:jellyfin-users"
              ];
            }
          ];
        };
      };
      clients = [
        {
          client_id = "actual-budget";
          client_name = "Actual Budget";
          client_secret = "$pbkdf2-sha512$310000$iWomIaFYWHHBwj3ILVzL.Q$l9rRfes89uaXIGQnSZqtlLsAa8zMkjHWvUL39mnjHXBq.bokav5Z.dc3.mcUZxkW.5M64InDQZ5eg/81HWlETA";
          public = false;
          authorization_policy = "internal_one_factor";
          grant_types = [
            "authorization_code"
          ];
          redirect_uris = [
            "https://budget.${domain}/openid/callback"
            "https://money.${domain}/openid/callback"
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
        {
          client_id = "cloudflare";
          client_name = "Cloudflare Access";
          client_secret = "$pbkdf2-sha512$310000$0OVYTmffbZnm5QLF/aPQIA$AaOM/qZFPwy.f4sQSQW.NOsm302CovCx3osVs/C8bfTEOt1tpbsf.lSZqBCY97JBG5PAr/IuIJg2RS2rz/PT7g";
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
          client_id = "forgejo";
          client_name = "Forgejo";
          client_secret = "$pbkdf2-sha512$310000$jZCkAHO4SX26j3DUiyRpfw$kbL7tPjDrbLK4YtFt7kLLKl2LfWoWghrp8bJFCfmKGCgKa2RXUiu1B2C/Tx19Xfn38J7z/ToB0ckgvp15CY99A";
          public = false;
          authorization_policy = "internal_one_factor";
          grant_types = [
            "authorization_code"
          ];
          redirect_uris = [
            "https://git.${domain}/user/oauth2/authelia/callback"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
        {
          client_id = "grafana";
          client_name = "Grafana";
          client_secret = "$pbkdf2-sha512$310000$nWiTXHRVFg.0p0DFs0Fr9Q$ZkDnbKytBDwzW7JAdmreKAFnsdk93k5Y91WqefgppXayVU6xVtGokDj2/qoyzqbBgP2FhX0Jg7Vf4ADOWdIuWA";
          public = false;
          authorization_policy = "internal_one_factor";
          claims_policy = "grafana";
          grant_types = [
            "authorization_code"
          ];
          redirect_uris = [
            "https://grafana.${domain}/login/generic_oauth"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
        {
          client_id = "immich";
          client_name = "Immich";
          client_secret = "$pbkdf2-sha512$310000$we2.VRlN/pvtnZoUt0.kpw$qRAAKL..H4GnzEzMiMH.MPoXLy0IB3BslhB2.0gTVK99cuAyQEOsNNQ052huyqgpwdpTHVfaU68CmUzC.gnLGg";
          public = false;
          authorization_policy = "internal_one_factor";
          redirect_uris = [
            "https://photos.${domain}/auth/login"
            "https://photos.${domain}/user-settings"
            "app.immich:///oauth-callback"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_post";
        }
        {
          client_id = "jellyfin";
          client_name = "Jellyfin";
          client_secret = "$pbkdf2-sha512$310000$6MaPLvchHznyIyOpGM0pjw$wIBCSHF5R57zG9DtXyDn65jhPpkBL63/4PXh.MSYbiRxln.jg65OAF.E.cluk9ljSayfy1GemMYMAZG82JcwFg";
          public = false;
          authorization_policy = "jellyfin_access";
          redirect_uris = [
            "https://stream.${domain}/sso/OID/redirect/authelia"
          ];
          scopes = [
            "openid"
            "profile"
            "groups"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_post";
        }
        {
          client_id = "linkding";
          client_name = "Linkding";
          client_secret = "$pbkdf2-sha512$310000$jXF45KQfnCDkLgwYlPFUSg$KKe9Gno3dHq8uZkyD9ItqU4mVXkhkk2zfdHTsqpbWcp8oxkxZ5nAgwqgj.wpnTW.NkXs66zFdSdSFT3t2b04gA";
          public = false;
          authorization_policy = "internal_one_factor";
          redirect_uris = [
            "https://links.${domain}/oidc/callback/"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_post";
        }
        {
          client_id = "mealie";
          client_name = "Mealie";
          client_secret = "$pbkdf2-sha512$310000$2134vs5nM5P6LhYDJEGIKg$kJ4ddV127kSLE7FcVHReV/mZ9d6rjT.mntrKqoh.8WndDhoCLf3laThkNbvYnQKGu6wo3FNNuGMkmD0tNP8Xsg";
          public = false;
          authorization_policy = "mealie_access";
          grant_types = [ "authorization_code" ];
          redirect_uris = [ "https://meals.${domain}/login" ];
          scopes = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
        {
          client_id = "miniflux";
          client_name = "Miniflux";
          client_secret = "$pbkdf2-sha512$310000$ixsi8LqA7zxNPLXbpjqSAQ$1GQ.NssJ/QKvD7qCgwxsT7PFpD4ZxilDDq17.GSqFbcqueNGJy.2Jv8xYszFjumkE7pLNTbG0Lg6bR2clzTXvw";
          public = false;
          authorization_policy = "internal_one_factor";
          redirect_uris = [
            "https://rss.${domain}/oauth2/oidc/callback"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
        {
          client_id = "paperless";
          client_name = "Paperless";
          client_secret = "$pbkdf2-sha512$310000$L2POBBIm7MhKxfGUwCXZNg$hqRUxAB4wBa3jMePdFMIG6jFOYdstgMiowwzc11RaOJMyj4eBr74ZJY1jClATbCx51oTO.JRz1TGgtzcrOegnQ";
          public = false;
          authorization_policy = "internal_one_factor";
          redirect_uris = [
            "https://paperless.${domain}/accounts/oidc/authelia/login/callback/"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
        {
          client_id = "tandoor";
          client_name = "Tandoor";
          client_secret = "$pbkdf2-sha512$310000$zyxRgO3vxU1QQI/doVsRaQ$wHW9bDWtBitWrQgRuOHi5lOVtfC44NC12mDD3JXUGtsA8JCARTsVUlUnt42KyON5RzlYO95UVr.tJlDURcS.Bw";
          public = false;
          authorization_policy = "internal_one_factor";
          grant_types = [
            "authorization_code"
          ];
          redirect_uris = [
            "https://recipes.${domain}/accounts/oidc/authelia/login/callback/"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
        {
          client_id = "tailscale";
          client_name = "Tailscale";
          client_secret = "$pbkdf2-sha512$310000$oQVBGFNKM9uiscpWlEMzmw$9qZf/57tlwlmZX.Ni2tlkQH7h3LJRiCTw7D5uJGG8HVApcd1m/1GUTnd01F/os9jpW7wqH0mvabyuXMmz5MDzQ";
          redirect_uris = [
            "https://login.tailscale.com/a/oauth_response"
          ];
          scopes = [
            "openid"
            "email"
            "profile"
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
    address = "tcp://:${toString ports.authelia}/";
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
    address = "tcp://:${toString ports.exporters.authelia}/metrics";
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
