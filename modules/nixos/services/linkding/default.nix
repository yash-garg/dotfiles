{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.linkding;
in
{
  options.${namespace}.services.linkding = {
    enable = mkEnableOption "Easy to use self-hosted bookmark manager";
    port = mkOpt types.port ports.linkding "The port for the linkding service";
    proxy = {
      enable = mkEnableOption "Enable the linkding Caddy proxy";
      domain = mkOpt types.str "yashgarg.dev" "The domain name for the linkding service";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.linkding-env = {
      sopsFile = lib.dots.get-file "secrets/linkding.env";
      format = "dotenv";
    };

    services.linkding = enabled // {
      inherit (cfg) port;
      environmentFile = config.sops.secrets.linkding-env.path;
      database = {
        type = "postgres";
        createLocally = true;
        # user/name must match services.linkding.user when createLocally = true
        user = "linkding";
        name = "linkding";
      };
      settings = {
        LD_CSRF_TRUSTED_ORIGINS = "https://links.${cfg.proxy.domain}";
        LD_DISABLE_LOGIN_FORM = "True";
        LD_ENABLE_AUTH_PROXY = "True";
        LD_AUTH_PROXY_USERNAME_HEADER = "HTTP_REMOTE_USER";
        LD_AUTH_PROXY_LOGOUT_URL = "https://auth.${cfg.proxy.domain}/logout";
        LD_ENABLE_OIDC = "False";
      };
    };

    dots.services.caddy.services.links = mkIf cfg.proxy.enable {
      inherit (cfg.proxy) domain;
      upstream = "localhost:${toString cfg.port}";
    };
  };
}
