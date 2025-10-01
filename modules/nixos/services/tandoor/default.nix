{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.tandoor;
in
{
  options.${namespace}.services.tandoor = {
    enable = mkEnableOption "Tandoor: Recipe Management System";
    domain = mkOpt types.str "ipx.ovh" "Domain name for tandoor";
  };

  config = mkIf cfg.enable {
    sops.secrets.tandoor-env = {
      inherit (config.services.tandoor-recipes) group;
      owner = config.services.tandoor-recipes.user;
      sopsFile = snowfall.fs.get-file "secrets/tandoor.env";
      format = "dotenv";
    };

    services = {
      tandoor-recipes = enabled // {
        address = "0.0.0.0";
        database.createLocally = true;
        extraConfig = {
          ALLOWED_HOSTS = "recipes.${cfg.domain},0.0.0.0";
          ENABLE_METRICS = 1;
          ENABLE_SIGNUP = 0;
        };
        port = ports.tandoor;
      };

      prometheus.scrapeConfigs = [
        {
          job_name = "tandoor-recipes";
          static_configs = [
            {
              targets = [
                "${config.services.tandoor-recipes.address}:${toString config.services.tandoor-recipes.port}"
              ];
            }
          ];
        }
      ];

      traefik.dynamicConfigOptions.http = {
        routers.tandoor-recipes = {
          rule = "Host(`recipes.${cfg.domain}`)";
          entryPoints = [ "websecure" ];
          service = "tandoor-recipes";
          tls.certResolver = "letsencrypt";
        };
        services.tandoor-recipes.loadBalancer = {
          servers = [ { url = "http://localhost:${toString config.services.tandoor-recipes.port}"; } ];
        };
      };
    };

    systemd.services.tandoor-recipes = {
      serviceConfig.EnvironmentFile = [ config.sops.secrets.tandoor-env.path ];
      after = [ "postgresql.service" ];
    };
  };
}
