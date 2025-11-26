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
  cfg = config.${namespace}.services.calibre-web;
  emptyMetadataDB = pkgs.fetchurl {
    url = "https://github.com/janeczku/calibre-web/raw/refs/tags/0.6.25/library/metadata.db";
    hash = "sha256-+sL34370vA+ylV6aP2EmBHB9TvVzr1wovXqDaTOfS9Q=";
  };
in
{
  options.${namespace}.services.calibre-web = {
    enable = mkEnableOption "Calibre Web: Web interface for Calibre";
    port = mkOpt types.int ports.calibre "The port for the calibre-web service";
    user = mkOpt types.str "calibre-web" "The user for the calibre-web service";
    group = mkOpt types.str "calibre-web" "The group for the calibre-web service";
    mediaDir = mkOpt types.str "/var/lib/calibre-web" "The media directory for the calibre-web service";
  };

  config = mkIf cfg.enable {
    services.calibre-web = enabled // {
      inherit (cfg) user group;
      listen = {
        inherit (cfg) port;
        ip = "0.0.0.0";
      };
      openFirewall = true;
      options = {
        calibreLibrary = cfg.mediaDir;
        enableBookUploading = true;
        enableKepubify = true;
        reverseProxyAuth = enabled // {
          header = "Remote-User";
        };
      };
    };

    systemd.services.calibre-web-init-db = {
      serviceConfig = {
        Type = "oneshot";
        TimeoutStartSec = "60";
      };
      wantedBy = [ "multi-user.target" ];
      before = [ "calibre-web.service" ];
      script = ''
        set -euo pipefail
        if [ ! -f ${cfg.mediaDir}/metadata.db ]; then
          install -Dm666 ${emptyMetadataDB} ${cfg.mediaDir}/metadata.db
          chown -R ${cfg.user}:${cfg.group} ${cfg.mediaDir}
        fi
      '';
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.mediaDir} 0775 ${cfg.user} ${cfg.group} -"
    ];
  };
}
