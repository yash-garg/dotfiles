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
  cfg = config.${namespace}.services.immich;
in
{
  options.${namespace}.services.immich = {
    enable = mkEnableOption "Enable Immich: Photo Management System";
    domain = mkOpt types.str "ipx.ovh" "The domain name for the immich service";
    port = mkOpt types.int ports.immich "Port for the immich service";
  };

  config = mkIf cfg.enable {
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
          IMMICH_IGNORE_MOUNT_CHECK_ERRORS = "true";
          IMMICH_TELEMETRY_INCLUDE = "all";
        };
        openFirewall = true;
        machine-learning = enabled;
        redis = enabled;
        settings = {
          backup.database.enabled = false;
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

      traefik.dynamicConfigOptions.http = {
        routers.immich = {
          rule = "Host(`photos.${cfg.domain}`)";
          entryPoints = [ "websecure" ];
          service = "immich";
          tls.certResolver = "letsencrypt";
        };
        services.immich.loadBalancer = {
          servers = [ { url = "http://localhost:${toString cfg.port}"; } ];
        };
      };
    };

    users.users.immich.extraGroups = [
      "video"
      "render"
    ];
  };
}
