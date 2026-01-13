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
  cfg = config.${namespace}.services.ollama;
in
{
  options.${namespace}.services.ollama = {
    enable = mkEnableOption "Ollama AI";
    domain = mkOpt types.str "ipx.ovh" "Domain name for ollama";
    port = mkOpt types.int ports.ollama "Port to listen on";
    webui-port = mkOpt types.int ports.open-webui "Port to listen on for the web UI";
  };

  config = mkIf cfg.enable {
    services = {
      ollama = enabled // {
        inherit (cfg) port;
        host = "0.0.0.0";
        loadModels = [ "deepseek-r1:8b" ];
        openFirewall = true;
        package = (pkgs.ollama.override { acceleration = "cuda"; });
      };

      open-webui = enabled // {
        host = "0.0.0.0";
        port = cfg.webui-port;
        openFirewall = true;
        environment = {
          OLLAMA_BASE_URL = "http://localhost:${toString cfg.port}";
          ENABLE_OLLAMA_API = "true";
          DEFAULT_USER_ROLE = "user";
          WEBUI_URL = "https://chat.${cfg.domain}";
          WEBUI_AUTH_TRUSTED_EMAIL_HEADER = "Remote-Email";
          WEBUI_AUTH_TRUSTED_NAME_HEADER = "Remote-Name";
          WEBUI_AUTH_TRUSTED_GROUPS_HEADER = "Remote-Groups";
          ANONYMIZED_TELEMETRY = "False";
          DO_NOT_TRACK = "True";
          SCARF_NO_ANALYTICS = "True";
        };
      };

      traefik.dynamicConfigOptions.http = {
        routers.open-webui = {
          rule = "Host(`chat.${cfg.domain}`)";
          entryPoints = [ "websecure" ];
          service = "open-webui";
          middlewares = [
            "crowdsec"
            "auth"
          ];
          tls.certResolver = "letsencrypt";
        };

        services.open-webui.loadBalancer = {
          servers = [ { url = "http://localhost:${toString cfg.webui-port}"; } ];
        };
      };
    };
  };
}
