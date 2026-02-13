{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.n8n;
  hooksFile = pkgs.writeText "n8n-hooks.js" (
    replaceStrings [ "@N8N_BASE_PATH@" "@DOMAIN@" ] [ "${pkgs.n8n}/lib/n8n" cfg.domain ] (
      builtins.readFile ./hooks.js
    )
  );
in
{
  options.${namespace}.services.n8n = {
    enable = mkEnableOption "n8n: Workflow Automation";
    domain = mkOpt types.str "ipx.ovh" "The domain for n8n";
    port = mkOpt types.int ports.n8n "The port for n8n";
  };

  config = mkIf cfg.enable {
    services = {
      n8n = enabled // {
        environment = {
          DB_TYPE = "postgresdb";
          DB_POSTGRESDB_HOST = "/run/postgresql";
          DB_POSTGRESDB_DATABASE = "n8n";
          DB_POSTGRESDB_USER = "n8n";
          EXECUTIONS_DATA_PRUNE = "true";
          EXECUTIONS_DATA_MAX_AGE = "336"; # 2 weeks
          # Custom hooks and SSO configuration
          EXTERNAL_HOOK_FILES = "${hooksFile}";
          N8N_FORWARD_AUTH_HEADER = "Remote-Email";
          N8N_HIRING_BANNER_ENABLED = "false";
          N8N_PORT = toString cfg.port;
          N8N_SSO_HOSTNAME = "n8n.${cfg.domain}";
          WEBHOOK_URL = "https://n8n.${cfg.domain}";
        };
        openFirewall = true;
      };

      postgresql = {
        ensureDatabases = [ "n8n" ];
        ensureUsers = [
          {
            name = "n8n";
            ensureDBOwnership = true;
          }
        ];
      };

      traefik.dynamic.files.n8n.settings.http = {
        routers.n8n = {
          rule = "Host(`n8n.${cfg.domain}`)";
          entryPoints = [ "websecure" ];
          service = "n8n";
          tls.certResolver = "letsencrypt";
        };

        services.n8n.loadBalancer = {
          servers = [ { url = "http://localhost:${toString cfg.port}"; } ];
        };
      };
    };
  };
}
