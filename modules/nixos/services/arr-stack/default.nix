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
    user = mkOpt types.str "media" "The user to run the services as";
    group = mkOpt types.str "media" "The group to run the services as";
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      radarr-key = {
        sopsFile = snowfall.fs.get-file "secrets/arr-stack.env";
        format = "dotenv";
        key = "radarr_key";
      };
      readarr-key = {
        sopsFile = snowfall.fs.get-file "secrets/arr-stack.env";
        format = "dotenv";
        key = "readarr_key";
      };
      sonarr-key = {
        sopsFile = snowfall.fs.get-file "secrets/arr-stack.env";
        format = "dotenv";
        key = "sonarr_key";
      };
    };

    dots.services.qbittorrent = enabled // {
      inherit (cfg) group;
    };

    services =
      let
        defaults = enabled // {
          inherit (cfg) group;
          openFirewall = true;
        };
      in
      {
        prometheus = {
          exporters = {
            exportarr-radarr = enabled // {
              port = ports.exporters.radarr;
              apiKeyFile = config.sops.secrets.radarr-key.path;
            };
            exportarr-readarr = enabled // {
              port = ports.exporters.readarr;
              apiKeyFile = config.sops.secrets.readarr-key.path;
            };
            exportarr-sonarr = enabled // {
              port = ports.exporters.sonarr;
              apiKeyFile = config.sops.secrets.sonarr-key.path;
            };
          };
          scrapeConfigs = [
            {
              job_name = "radarr_exporter";
              static_configs = [ { targets = [ "127.0.0.1:${toString ports.exporters.radarr}" ]; } ];
            }
            {
              job_name = "readarr_exporter";
              static_configs = [ { targets = [ "127.0.0.1:${toString ports.exporters.readarr}" ]; } ];
            }
            {
              job_name = "sonarr_exporter";
              static_configs = [ { targets = [ "127.0.0.1:${toString ports.exporters.sonarr}" ]; } ];
            }
          ];
        };

        radarr = defaults // {
          settings.server.port = ports.radarr;
        };

        readarr = defaults // {
          settings.server.port = ports.readarr;
        };

        sonarr = defaults // {
          settings.server.port = ports.sonarr;
        };

        jellyfin = defaults;
      };

    systemd.tmpfiles.rules =
      let
        inherit (config.users.users.${cfg.user}) home;
      in
      [
        "d ${home} 0775 ${cfg.user} ${cfg.group} -"
        "d ${home}/downloads 0775 ${cfg.user} ${cfg.group} -"
        "d ${home}/downloads/.incomplete 0775 ${cfg.user} ${cfg.group} -"
      ];

    # Dedicated user for torrent/media automation
    users.users = mkIf (cfg.user == "media") {
      media = {
        inherit (cfg) group;
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "tty"
        ];
        home = "/home/media";
        homeMode = "0775";
        createHome = true;
        description = "Media automation user";
      };
    };

    users.groups = mkIf (cfg.group == "media") {
      media = {
        gid = null;
        members = [
          "qbittorrent"
          "radarr"
          "readarr"
          "sonarr"
          "jellyfin"
        ];
      };
    };
  };
}
