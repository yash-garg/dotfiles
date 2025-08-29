{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.gitea;
in
{
  options.${namespace}.services.gitea = {
    enable = mkEnableOption { description = "Whether to enable gitea"; };
    domain = mkOpt types.str "" "The domain name for gitea";
    openFirewall = mkBoolOpt false "Whether to open the firewall for gitea";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
      config.services.gitea.settings.server.HTTP_PORT
    ];

    services.gitea = enabled // {
      lfs = enabled;
      settings = {
        actions.ENABLED = false;
        database.type = "sqlite3";
        markdown.ENABLE_MATH = true;
        other.SHOW_FOOTER_POWERED_BY = false;
        repository.DISABLE_STARS = false;
        server = {
          DOMAIN = cfg.domain;
          DISABLE_SSH = true;
          ENABLE_GZIP = true;
          LANDING_PAGE = "explore";
          ROOT_URL = "https://${cfg.domain}/";
          HTTP_PORT = ports.gitea;
        };
        service = {
          COOKIE_SECURE = true;
          DISABLE_REGISTRATION = true;
        };
        ui.DEFAULT_THEME = "catppuccin-mocha-mauve";
      };
    };
  };
}
