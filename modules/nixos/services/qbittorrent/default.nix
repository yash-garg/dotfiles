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
    webuiPort = mkOpt types.int ports.qbittorrent.webui "The port for the web UI";
  };

  config = mkIf cfg.enable {
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
      upstream = "localhost:${toString cfg.webuiPort}";
    };
  };
}
