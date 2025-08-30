{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.plausible;
in
{
  options.${namespace}.services.plausible = {
    enable = mkEnableOption "Enable plausible analytics";

    baseUrl = mkOption {
      type = types.str;
      default = "yashgarg.dev";
      description = "Base URL for the plausible server";
    };

    secretKeybaseFile = mkOption {
      type = types.path;
      default = null;
      description = "Path to a file containing the secret key for the plausible server";
    };

    openFirewall = mkBoolOpt true "Open firewall for Plausible";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ ports.plausible ];

    services = {
      plausible = enabled // {
        database.postgres.setup = true;
        server = {
          baseUrl = "https://analytics.${cfg.baseUrl}";
          disableRegistration = "invite_only";
          port = ports.plausible;
          inherit (cfg) secretKeybaseFile;
        };
      };

      traefik.dynamicConfigOptions.http = {
        routers.plausible = {
          rule = "Host(`analytics.${cfg.baseUrl}`)";
          entryPoints = [ "websecure" ];
          service = "plausible";
          tls.certResolver = "letsencrypt";
        };
        services.plausible.loadBalancer = {
          servers = [ { url = "http://localhost:${toString ports.plausible}"; } ];
        };
      };
    };
  };
}
