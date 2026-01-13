{
  config,
  lib,
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
        acceleration = "cuda";
        host = "0.0.0.0";
        loadModels = [ "deepseek-r1:8b" ];
        openFirewall = true;
      };

      open-webui = enabled // {
        host = "0.0.0.0";
        port = cfg.webui-port;
        openFirewall = true;
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
