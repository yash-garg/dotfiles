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
        jellyfin = defaults;
        qbittorrent = defaults;
      };

    services = {
      bazarr = enabled // {
        inherit (cfg) group;
        listenPort = ports.bazarr;
        openFirewall = true;
      };

      prowlarr = enabled // {
        openFirewall = true;
        settings.server.port = ports.prowlarr;
      };

      radarr = enabled // {
        inherit (cfg) group;
        openFirewall = true;
        settings.server.port = ports.radarr;
      };

      sonarr = enabled // {
        inherit (cfg) group;
        openFirewall = true;
        settings.server.port = ports.sonarr;
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
