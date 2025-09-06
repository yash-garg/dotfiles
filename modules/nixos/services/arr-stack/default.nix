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
    dots.services.qbittorrent = enabled // {
      inherit (cfg) group;
    };

    networking.firewall.allowedTCPPorts = [
      ports.radarr
      ports.readarr
      ports.sonarr
    ];

    services =
      let
        defaults = enabled // {
          inherit (cfg) group;
          openFirewall = true;
        };
      in
      {
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
        home = config.users.users.${cfg.user}.home;
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
