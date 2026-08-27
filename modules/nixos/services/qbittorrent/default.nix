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
  cfg = config.${namespace}.services.qbittorrent;
in
{
  options.${namespace}.services.qbittorrent = {
    enable = mkEnableOption "qbittorrent: BitTorrent Client";
    domain = mkOpt types.str "ipx.ovh" "The domain name for the qbittorrent service";
    user = mkOpt types.str "qbittorrent" "The user to run qbittorrent as";
    group = mkOpt types.str "qbittorrent" "The group to run qbittorrent as";
    torrentingPort = mkOpt types.int ports.qbittorrent.torrenting "The port for torrenting";
    webuiPort =
      mkOpt types.int ports.qbittorrent.webui
        "The internal port for qBittorrent's own web UI";
    quiPort = mkOpt types.int ports.qui "The port for the qui web UI, fronting qBittorrent";
  };

  config = mkIf cfg.enable {
    sops.secrets.qui-session-secret = {
      sopsFile = lib.dots.get-file "secrets/qui.yaml";
      owner = cfg.user;
      inherit (cfg) group;
    };

    services.qui = enabled // {
      inherit (cfg) user group;
      secretFile = config.sops.secrets.qui-session-secret.path;
      settings = {
        host = "127.0.0.1";
        port = cfg.quiPort;
        # Authentication is handled upstream by Authelia; qui only accepts
        # traffic from the local reverse proxy.
        authDisabled = true;
        I_ACKNOWLEDGE_THIS_IS_A_BAD_IDEA = true;
        authDisabledAllowedCIDRs = [ "127.0.0.1/32" ];
      };
    };

    systemd.services.qui.after = [ "qbittorrent.service" ];

    services.qbittorrent = enabled // {
      inherit (cfg)
        user
        group
        torrentingPort
        webuiPort
        ;
      openFirewall = true;
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
            TrustedReverseProxiesList = trustedProxies.semicolonSeparated;
            Username = "yash";
          };
          General.Locale = "en";
        };
      };
    };

    dots.services.caddy.services.qbit = {
      inherit (cfg) domain;
      upstream = "localhost:${toString cfg.quiPort}";
    };
  };
}
