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
    sops.secrets.open-webui-env = {
      sopsFile = snowfall.fs.get-file "secrets/open-webui.env";
      format = "dotenv";
    };

    services = {
      ollama = enabled // {
        inherit (cfg) port;
        host = "0.0.0.0";
        loadModels = [
          "deepseek-r1:8b"
          "llama3.1:8b"
          "mistral:7b"
          "qwen2.5:7b"
        ];
        openFirewall = true;
        package = pkgs.ollama.override { acceleration = "cuda"; };
      };

      open-webui = enabled // {
        host = "0.0.0.0";
        port = cfg.webui-port;
        openFirewall = true;
        environment = {
          ENV = "prod";
          OLLAMA_BASE_URL = "http://localhost:${toString cfg.port}";
          ENABLE_OLLAMA_API = "True";
          ENABLE_OAUTH_SIGNUP = "True";
          ENABLE_PERSISTENT_CONFIG = "False";
          ENABLE_OAUTH_PERSISTENT_CONFIG = "False";
          DEFAULT_USER_ROLE = "user";
          ENABLE_ADMIN_CHAT_ACCESS = "False";
          WEBUI_URL = "https://chat.${cfg.domain}";
          WEBUI_AUTH_TRUSTED_EMAIL_HEADER = "Remote-Email";
          WEBUI_AUTH_TRUSTED_NAME_HEADER = "Remote-Name";
          WEBUI_AUTH_TRUSTED_GROUPS_HEADER = "Remote-Groups";
          WEBUI_AUTH_SIGNOUT_REDIRECT_URL = "https://auth.${cfg.domain}/logout";
          WEBUI_SESSION_COOKIE_SECURE = "True";
          WEBUI_AUTH_COOKIE_SECURE = "True";
          ANONYMIZED_TELEMETRY = "False";
          DO_NOT_TRACK = "True";
          SCARF_NO_ANALYTICS = "True";
        };
        environmentFile = config.sops.secrets.open-webui-env.path;
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
