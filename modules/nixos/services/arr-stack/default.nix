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
  cfg = config.${namespace}.services.arr-stack;
in
{
  options.${namespace}.services.arr-stack = {
    enable = mkEnableOption "Enable the full media automation stack";
    mediaDirs = mkOpt (types.listOf types.str) [ ] "The media directories to use for the services";
    user = mkOpt types.str "media" "The user to run the services as";
    group = mkOpt types.str "media" "The group to run the services as";
  };

  config = mkIf cfg.enable {
    services =
      let
        defaults = enabled // {
          inherit (cfg) group;
          openFirewall = true;
        };
      in
      {
        qbittorrent = defaults // {
          inherit (cfg) user;
          torrentingPort = ports.qbittorrent.torrenting;
          webuiPort = ports.qbittorrent.webui;
          serverConfig = {
            BitTorrent.Session = {
              AddTorrentStopped = true;
              GlobalMaxInactiveSeedingMinutes = 60;
              GlobalMaxRatio = -1;
              GlobalMaxSeedingMinutes = 60;
              GlobalUPSpeedLimit = 100;
              ShareLimitAction = "Stop";
            };
            LegalNotice.Accepted = true;
            Preferences = {
              WebUI = {
                AlternativeUIEnabled = true;
                AuthSubnetWhitelist = "100.0.0.0/10, 127.0.0.0/8";
                AuthSubnetWhitelistEnabled = true;
                Password_PBKDF2 = "@ByteArray(vVAbbSGAmkemV9cSj95beg==:dcK684mnx6yHbTTOJ8yK0YjRSrARSNTPTy7AjOioIA+ixOU6IxVUUR5FHDmJQJO+nJElxCsV2X2WB96/rYqdmg==)";
                RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
                TrustedReverseProxiesList = "127.0.0.1";
                Username = "yash";
              };
              General.Locale = "en";
            };
          };
        };

        prowlarr = enabled // {
          openFirewall = true;
          settings.server.port = ports.prowlarr;
        };

        radarr = defaults // {
          settings.server.port = ports.radarr;
        };

        sonarr = defaults // {
          settings.server.port = ports.sonarr;
        };

        jellyfin = defaults;
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
          "qbittorrent"
          "radarr"
          "prowlarr"
          "sonarr"
          "jellyfin"
        ];
      };
    };
  };
}
