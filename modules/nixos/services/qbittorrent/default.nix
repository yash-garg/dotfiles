{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.qbittorrent;
  configDir = "${cfg.dataDir}/.config";
in
{
  options.${namespace}.services.qbittorrent = {
    enable = mkBoolOpt false "Enable qbittorrent-nox service.";

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/qbittorrent";
      description = ''
        Directory where qBittorrent-nox will create files.
      '';
    };

    user = mkOption {
      type = types.str;
      default = "qbittorrent";
      description = "The user which qbittorrent will run on";
    };

    group = mkOption {
      type = types.str;
      default = "qbittorrent";
      description = "The group of the user which qbittorrent will run on";
    };

    openFirewall = mkBoolOpt true "Open the firewall for qbittorrent";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.qbittorrent-nox ];

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ ports.qbittorrent ];
      allowedUDPPorts = [ ports.qbittorrent ];
    };

    systemd.services.qbittorrent = {
      after = [ "network.target" ];
      description = "qBittorrent Daemon";
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.qbittorrent-nox ];
      serviceConfig = {
        ExecStart = ''
          ${pkgs.qbittorrent-nox}/bin/qbittorrent-nox \
            --profile=${configDir} \
            --webui-port=${toString ports.qbittorrent}
        '';
        Restart = "on-success";
        User = cfg.user;
        Group = cfg.group;
      };
    };

    systemd.tmpfiles.rules = [ "d '${cfg.dataDir}' 0700 ${cfg.user} ${cfg.group} - -" ];

    users.users = mkIf (cfg.user == "qbittorrent") {
      qbittorrent = {
        description = "qBittorrent Daemon user";
        inherit (cfg) group;
        home = cfg.dataDir;
        isSystemUser = true;
      };
    };

    users.groups = mkIf (cfg.group == "qbittorrent") {
      qbittorrent = {
        gid = null;
      };
    };
  };
}
