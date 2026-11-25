{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.arr-stack;
in
{
  options.${namespace}.services.arr-stack = {
    enable = mkEnableOption "Enable the full media automation stack";
    mediaDirs = mkOpt (types.listOf types.str) [ ] "The media directories to use for the services";
    domain = mkOpt types.str "ipx.ovh" "The domain to use for the services";
    user = mkOpt types.str "media" "The user to run the services as";
    group = mkOpt types.str "media" "The group to run the services as";
  };

  config = mkIf cfg.enable {
    dots.services =
      let
        defaults = enabled // {
          inherit (cfg) user group;
        };
      in
      {
        backend-health.endpoints = {
          bazarr = {
            port = ports.bazarr;
            statuses = [
              200
              302
            ];
          };
          prowlarr.port = ports.prowlarr;
          radarr.port = ports.radarr;
          sonarr.port = ports.sonarr;
        };

        caddy.services = {
          radarr = {
            inherit (cfg) domain;
            upstream = "localhost:${toString ports.radarr}";
          };
          sonarr = {
            inherit (cfg) domain;
            upstream = "localhost:${toString ports.sonarr}";
          };
          prowlarr = {
            inherit (cfg) domain;
            upstream = "localhost:${toString ports.prowlarr}";
          };
          bazarr = {
            inherit (cfg) domain;
            upstream = "localhost:${toString ports.bazarr}";
          };
        };
        jellyfin = defaults;
        qbittorrent = defaults;
      };

    services = {
      bazarr = enabled // {
        inherit (cfg) group;
        settings.general = {
          ip = "127.0.0.1";
          port = ports.bazarr;
        };
        openFirewall = false;
      };

      prowlarr = enabled // {
        openFirewall = false;
        settings = {
          auth.authenticationMethod = "External";
          server = {
            port = ports.prowlarr;
            bindaddress = "127.0.0.1";
          };
        };
      };

      radarr = enabled // {
        inherit (cfg) group;
        openFirewall = false;
        settings = {
          auth.authenticationMethod = "External";
          server = {
            port = ports.radarr;
            bindaddress = "127.0.0.1";
          };
        };
      };

      sonarr = enabled // {
        inherit (cfg) group;
        openFirewall = false;
        settings = {
          auth.authenticationMethod = "External";
          server = {
            port = ports.sonarr;
            bindaddress = "127.0.0.1";
          };
        };
      };
    };

    systemd.tmpfiles.rules = lib.concatMap (dir: [
      "d ${dir} 0775 ${cfg.user} ${cfg.group} -"
      "d ${dir}/movies 0775 ${cfg.user} ${cfg.group} -"
      "d ${dir}/tv 0775 ${cfg.user} ${cfg.group} -"
    ]) cfg.mediaDirs;

    # Dedicated user for torrent/media automation
    users.users = mkIf (cfg.user == "media") {
      media = {
        inherit (cfg) group;
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "tty"
        ];
        description = "Media automation user";
      };
    };

    users.groups = mkIf (cfg.group == "media") {
      media = {
        gid = null;
        members = [
          "bazarr"
          "jellyfin"
          "prowlarr"
          "qbittorrent"
          "radarr"
          "sonarr"
        ];
      };
    };
  };
}
