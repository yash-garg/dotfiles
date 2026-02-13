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
  srv = config.${namespace}.services;
  cfg = srv.immich;
in
{
  options.${namespace}.services.immich = {
    enable = mkEnableOption "Enable Immich: Photo Management System";
    domain = mkOpt types.str "ipx.ovh" "The domain name for the immich service";
    mediaDir = mkOpt types.str "/var/lib/immich" "The directory for the immich media";
    port = mkOpt types.int ports.immich.webui "Port for the immich service";
    backup = {
      enable = mkEnableOption "Enable restic backup for Immich";
      url = mkOpt types.str "s3.eu-central-003.backblazeb2.com" "Restic repository URL";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ ports.immich.machine-learning ];

    sops.secrets =
      let
        defaultAttrs = {
          sopsFile = snowfall.fs.get-file "secrets/immich.yaml";
          owner = config.services.immich.user;
        };
      in
      {
        immich-client-id = defaultAttrs // {
          key = "client_id";
        };

        immich-client-secret = defaultAttrs // {
          key = "client_secret";
        };

        immich-restic = defaultAttrs // {
          key = "restic";
        };
      };

    sops.templates."immich-config.json" = {
      file = (pkgs.formats.json { }).generate "immich.json" config.services.immich.settings;
      owner = config.services.immich.user;
    };

    services = {
      immich = enabled // {
        inherit (cfg) port;
        # GPU access for machine learning
        accelerationDevices = [ "/dev/dri/renderD128" ];
        database = enabled // {
          createDB = true;
          enableVectorChord = true;
          enableVectors = true;
        };
        environment = {
          IMMICH_API_METRICS_PORT = toString ports.exporters.immich;
          IMMICH_CONFIG_FILE = mkForce config.sops.templates."immich-config.json".path;
          IMMICH_HOST = mkForce "0.0.0.0";
          IMMICH_IGNORE_MOUNT_CHECK_ERRORS = "true";
          IMMICH_TELEMETRY_INCLUDE = "all";
        };
        openFirewall = true;
        machine-learning = enabled // {
          environment = {
            IMMICH_HOST = mkForce "0.0.0.0";
            IMMICH_PORT = toString ports.immich.machine-learning;
            HF_XET_CACHE = "/var/cache/immich/huggingface-xet";
          };
        };
        mediaLocation = cfg.mediaDir;
        redis = enabled;
        settings = {
          backup.database.enabled = false;
          job = {
            faceDetection.concurrency = 10;
            thumbnailGeneration.concurrency = 50;
          };
          newVersionCheck.enabled = false;
          oauth = {
            autoLaunch = true;
            autoRegister = true;
            buttonText = "Login with Authelia";
            clientId = config.sops.placeholder.immich-client-id;
            clientSecret = config.sops.placeholder.immich-client-secret;
            enabled = true;
            issuerUrl = "https://auth.${cfg.domain}/.well-known/openid-configuration";
            mobileOverrideEnabled = false;
            scope = "openid email profile";
            signingAlgorithm = "RS256";
            storageLabelClaim = "preferred_username";
          };
          passwordLogin.enabled = false;
          server.externalDomain = "https://photos.${cfg.domain}";
        };
      };

      prometheus.scrapeConfigs = [
        {
          job_name = "immich";
          static_configs = [ { targets = [ "127.0.0.1:${toString ports.exporters.immich}" ]; } ];
        }
      ];

      restic.backups.immich = mkIf (cfg.backup.enable && srv.restic.enable) (
        srv.restic.mkBackup "immich" {
          environmentFile = config.sops.secrets.immich-restic.path;
          exclude = [ "${cfg.mediaDir}/encoded-video" ];
          paths = [ cfg.mediaDir ];
          repository = "s3:${cfg.backup.url}/immich-backup-nova";
          timerConfig.OnCalendar = "weekly";
        }
      );

      traefik.dynamic.files.immich.settings.http = {
        routers.immich = {
          rule = "Host(`photos.${cfg.domain}`)";
          entryPoints = [ "websecure" ];
          middlewares = [ "crowdsec" ];
          service = "immich";
          tls.certResolver = "letsencrypt";
        };
        services.immich.loadBalancer = {
          servers = [ { url = "http://localhost:${toString cfg.port}"; } ];
        };
      };
    };

    systemd.tmpfiles.rules =
      let
        inherit (config.services.immich) user;
        inherit (config.services.immich) group;
      in
      [
        "d ${cfg.mediaDir} 0775 ${user} ${group} -"
      ];

    users.users.immich.extraGroups = [
      "video"
      "render"
    ];
  };
}
