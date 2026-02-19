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
  cfg = config.${namespace}.services.forgejo;
in
{
  options.${namespace}.services.forgejo = {
    enable = mkEnableOption { description = "Whether to enable forgejo"; };
    domain = mkOpt types.str "ipx.ovh" "The domain name for forgejo";
  };

  config = mkIf cfg.enable {
    services = {
      forgejo = enabled // {
        database = {
          type = "postgres";
          createDatabase = true;
        };
        package = pkgs.forgejo;
        settings = {
          actions.ENABLED = false;
          api.ENABLE_SWAGGER = false;
          "cron.update_mirrors".PULL_LIMIT = -1;
          "cron.delete_repo_archives" = {
            ENABLED = true;
            SCHEDULE = "@daily";
          };
          "cron.git_gc_repos" = {
            ENABLED = true;
            ARGS = "--aggressive --auto";
          };
          "cron.update_checker".ENABLED = false;
          federation.ENABLED = true;
          git.GC_ARGS = "--aggressive --auto";
          "git.config"."diff.algorithm" = "patience";
          DEFAULT.APP_NAME = "Yash Garg's Git Hosting";
          mailer.ENABLED = false;
          mirror.DEFAULT_INTERVAL = "1h";
          oauth2.ACCESS_TOKEN_EXPIRATION_TIME = 86400;
          markdown.ENABLE_MATH = true;
          other.SHOW_FOOTER_POWERED_BY = false;
          repository = {
            DISABLE_HTTP_GIT = false;
            DISABLE_STARS = true;
            ENABLE_PUSH_CREATE_USER = true;
            DISABLE_DOWNLOAD_SOURCE_ARCHIVES = false;
          };
          "repository.pull-request" = {
            DEFAULT_MERGE_STYLE = "rebase";
            DEFAULT_MERGE_MESSAGE_ALL_AUTHORS = true;
          };
          server = {
            DOMAIN = cfg.domain;
            DISABLE_SSH = true;
            ENABLE_GZIP = true;
            LANDING_PAGE = "explore";
            ROOT_URL = "https://git.${cfg.domain}/";
            HTTP_PORT = ports.forgejo;
          };
          service = {
            DISABLE_REGISTRATION = true;
            ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
            ENABLE_INTERNAL_SIGNIN = false;
            DEFAULT_KEEP_EMAIL_PRIVATE = true;
          };
          session = {
            COOKIE_NAME = "i_dont_like_gitea";
            COOKIE_SECURE = true;
            DOMAIN = cfg.domain;
          };
          time.DEFAULT_UI_LOCATION = "Asia/Kolkata";
          "ui.meta" = {
            AUTHOR = "Yash Garg";
            DESCRIPTION = "Yash Garg's personal Git repositories";
          };
        };
      };

    };

    dots.services.caddy.services.git = {
      inherit (cfg) domain;
      upstream = "localhost:${toString config.services.forgejo.settings.server.HTTP_PORT}";
      auth = false;
    };
  };
}
