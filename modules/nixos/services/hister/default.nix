{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.hister;
in
{
  options.${namespace}.services.hister = {
    enable = mkEnableOption "hister: personal search engine";
    domain = mkOpt types.str "ipx.ovh" "Domain to serve hister on (as hister.<domain>)";
    port = mkOpt types.int ports.hister "Port to serve hister on";
  };

  config = mkIf cfg.enable {
    sops.secrets.hister-env = {
      sopsFile = snowfall.fs.get-file "secrets/hister.env";
      format = "dotenv";
    };

    services.hister = enabled // {
      inherit (cfg) port;
      dataDir = "/var/lib/hister";
      openFirewall = true;
      environmentFile = config.sops.secrets.hister-env.path;
      settings = {
        app.user_handling = true;
        server = {
          address = "127.0.0.1:${toString cfg.port}";
          base_url = "https://search.${cfg.domain}";
          database = "host=/run/postgresql dbname=hister sslmode=disable TimeZone=Asia/Kolkata";
          oauth_only = true;
          oauth.oidc = {
            configuration_url = "https://auth.${cfg.domain}/.well-known/openid-configuration";
          };
        };
      };
    };

    services.postgresql = {
      ensureDatabases = [ "hister" ];
      ensureUsers = [
        {
          name = "hister";
          ensureDBOwnership = true;
        }
      ];
    };

    dots.services.caddy.services.search = {
      inherit (cfg) domain;
      upstream = "localhost:${toString cfg.port}";
      auth = false;
    };
  };
}
