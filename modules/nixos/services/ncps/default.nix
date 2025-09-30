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
    sops.secrets.ncps-private-key.sopsFile = snowfall.fs.get-file "secrets/ncps.yaml";

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
            "https://cache.garnix.io"
            "https://ai.cachix.org"
            "https://nixpkgs-wayland.cachix.org"
            "https://yash-garg.cachix.org"
            "https://cache.nixos.org"
            "https://raspberry-pi-nix.cachix.org"
            "https://cosmic.cachix.org/"
          ];
          publicKeys = [
            "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
            "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
            "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
            "yash-garg.cachix.org-1:sHcKOvVej+RlINvt4XVAOE/Cnho3hnrHHRv0uq1u7Xs="
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "raspberry-pi-nix.cachix.org-1:WmV2rdSangxW0rZjY/tBvBDSaNFQ3DyEQsVw8EvHn9o="
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
