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
  cfg = config.${namespace}.services.copyparty;
  volumeType = types.submodule {
    options = {
      path = mkOpt types.path null "The path to serve";
      access = mkOpt types.attrs { } "The access control rules";
    };
  };
in
{
  options.${namespace}.services.copyparty = {
    enable = mkEnableOption "copyparty: portable file server";
    domain = mkOpt types.str "ipx.ovh" "The domain to serve copyparty on";
    user = mkOpt types.str "copyparty" "The user to run copyparty as";
    group = mkOpt types.str "copyparty" "The group to run copyparty as";
    port = mkOpt types.int ports.copyparty "The port for copyparty";
    package = mkOpt types.package (pkgs.copyparty.override {
      withHashedPasswords = false;
      withCertgen = false;
      withThumbnails = false;
      withFastThumbnails = true;
      withMediaProcessing = false;
      withBasicAudioMetadata = false;
      withZeroMQ = false;
      withFTP = false;
      withTFTP = false;
      withFTPS = false;
      withSMB = false;
      withMagic = false;
    }) "The package to use for copyparty";
    volumes = mkOpt (types.attrsOf volumeType) { } "The volumes to serve";
    extraSettings = mkOpt types.attrs { } "Extra settings to pass to copyparty";
  };

  config = mkIf cfg.enable {
    services = {
      copyparty = enabled // {
        inherit (cfg)
          package
          user
          group
          volumes
          ;
        mkHashWrapper = true;
        settings = {
          i = "0.0.0.0";
          p = toString cfg.port;
          theme = 2;
          e2dsa = true;
          e2ts = true;
          re-maxage = 3600;
          stats = true;
        }
        // cfg.extraSettings;
      };

      prometheus.scrapeConfigs = [
        {
          job_name = "copyparty";
          metrics_path = "/.cpr/metrics";
          static_configs = [
            { targets = [ "${config.services.copyparty.settings.i}:${toString cfg.port}" ]; }
          ];
        }
      ];

      traefik.dynamicConfigOptions.http = {
        routers.copyparty = {
          rule = "Host(`fs.${cfg.domain}`)";
          entryPoints = [ "websecure" ];
          service = "copyparty";
          tls.certResolver = "letsencrypt";
        };

        services.copyparty.loadBalancer = {
          servers = [ { url = "http://${config.services.copyparty.settings.i}:${toString cfg.port}"; } ];
        };
      };
    };

    users.users = mkIf (cfg.user == "copyparty") {
      copyparty = {
        inherit (cfg) group;
        description = "copyparty daemon user";
        isSystemUser = true;
      };
    };

    users.groups = mkIf (cfg.group == "copyparty") {
      copyparty = { };
    };
  };
}
