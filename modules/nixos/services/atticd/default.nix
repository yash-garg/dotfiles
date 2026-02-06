{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.atticd;
in
{
  options.${namespace}.services.atticd = {
    enable = mkEnableOption "atticd: binary cache server";
    bucket = mkOpt types.str "binary-cache" "The bucket for the attic cache";
    domain = mkOpt types.str "ipx.ovh" "The domain for the attic cache";
    endpoint = mkOpt types.str "" "The endpoint for the attic cache";
    port = mkOpt types.int ports.atticd "The port for the attic cache";
  };

  config = mkIf cfg.enable {
    sops.secrets.atticd-env = {
      sopsFile = lib.snowfall.fs.get-file "secrets/atticd.env";
      format = "dotenv";
    };

    services = {
      atticd = enabled // {
        package = pkgs.attic-server;
        environmentFile = config.sops.secrets.atticd-env.path;
        settings = {
          listen = "127.0.0.1:${toString cfg.port}";
          allowed-hosts = [ "cache.${cfg.domain}" ];
          api-endpoint = "https://cache.${cfg.domain}/";
          chunking = {
            nar-size-threshold = 8388608; # 8 MB
            min-size = 524288; # 512 KB
            max-size = 2097152; # 2 MB
            avg-size = 1048576; # 1 MB
          };
          database.url = "postgres://atticd/atticd?host=/run/postgresql";
          garbage-collection = {
            interval = "1 day";
            default-retention-period = "14 days";
          };
          storage = {
            inherit (cfg) bucket endpoint;
            type = "s3";
            region = "auto";
          };
        };
      };

      traefik.dynamicConfigOptions.http = {
        routers.atticd = {
          rule = "Host(`cache.${cfg.domain}`)";
          entryPoints = [ "websecure" ];
          middlewares = [ "crowdsec" ];
          service = "atticd";
          tls.certResolver = "letsencrypt";
        };
        services.atticd.loadBalancer = {
          servers = [ { url = "http://127.0.0.1:${toString cfg.port}"; } ];
        };
      };

      postgresql = enabled // {
        ensureUsers = [
          {
            name = "atticd";
            ensureDBOwnership = true;
          }
        ];
        ensureDatabases = [ "atticd" ];
      };
    };
  };
}
