{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.ncps;
in
{
  options.${namespace}.services.ncps = {
    enable = mkEnableOption "ncps, a Nix binary cache proxy";
  };

  config = mkIf cfg.enable {
    sops.secrets.ncps-private-key = {
      sopsFile = lib.dots.get-file "secrets/ncps.yaml";
      owner = "ncps";
    };

    services = {
      ncps = enabled // {
        logLevel = "info";
        prometheus = enabled;
        server.addr = "127.0.0.1:${toString ports.ncps}";
        cache = {
          allowDeleteVerb = false;
          allowPutVerb = false;
          hostName = "0.0.0.0";
          maxSize = "50G";
          secretKeyPath = config.sops.secrets.ncps-private-key.path;
          lru = {
            scheduleTimeZone = "Asia/Kolkata";
            # 8 AM every day
            schedule = "00 08 * * *";
          };
        };
        upstream = {
          caches = [
            "https://yash-garg.cachix.org"
            "https://cache.nixos.org"
            "https://cosmic.cachix.org/"
          ];
          publicKeys = [
            "yash-garg.cachix.org-1:sHcKOvVej+RlINvt4XVAOE/Cnho3hnrHHRv0uq1u7Xs="
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
          ];
        };
      };

      prometheus.scrapeConfigs = [
        {
          job_name = "ncps";
          static_configs = [ { targets = [ "${config.services.ncps.server.addr}" ]; } ];
        }
      ];
    };

    nix.settings = {
      substituters = mkForce [ "http://${config.services.ncps.server.addr}" ];
      trusted-public-keys = mkForce [ "0.0.0.0:MSBGCFZd41ii4zgYgOrrIqKtAuYqfhmF+2AS4QFCbxs=" ];
    };
  };
}
