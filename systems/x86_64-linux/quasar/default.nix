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
  hostName = "quasar";
in
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  sops.secrets = {
    user-password = {
      sopsFile = lib.dots.get-file "secrets/users.yaml";
      key = hostName;
      neededForUsers = true;
    };
    server-tsauthkey.sopsFile = lib.dots.get-file "secrets/tailscale.yaml";
    frigate-env = {
      sopsFile = lib.dots.get-file "secrets/frigate.env";
      format = "dotenv";
      mode = "0400";
    };
  };

  dots = {
    server = enabled;

    hardware.networking = enabled // {
      inherit hostName;
      ports = [
        22
      ];
    };

    services = {
      arr-stack = enabled // {
        mediaDirs = [
          "/mnt/media/main"
          "/mnt/media/samsung"
        ];
      };

      bentopdf = enabled;

      caddy = enabled // {
        auth = enabled // {
          url = "http://zenith.turtle-lake.ts.net:${toString ports.authelia}";
        };
        internal = enabled;
      };

      calibre-web = enabled // {
        mediaDir = "/mnt/books";
      };

      copyparty = enabled // {
        user = "yash";
        group = "users";
        waitForMounts = [
          "mnt-books.mount"
          "mnt-documents.mount"
          "mnt-media-main-movies.mount"
          "mnt-media-main-tv.mount"
          "mnt-media-samsung.mount"
          "mnt-photos.mount"
        ];
        volumes =
          let
            defaultAccess = {
              r.wmda = "yash";
            };
          in
          {
            "/books" = {
              path = "/mnt/books";
              access = defaultAccess;
            };
            "/documents" = {
              path = "/mnt/documents/documents/originals";
              access = defaultAccess;
            };
            "/downloads" = {
              path = "/mnt/downloads";
              access = defaultAccess;
            };
            "/media" = {
              path = "/mnt/media";
              access = defaultAccess;
            };
            "/photos" = {
              path = "/mnt/photos";
              access = defaultAccess;
            };
          };
      };

      frigate =
        let
          rtspUrl =
            channel:
            "rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@10.0.30.245:554/cam/realmonitor?channel=${toString channel}&subtype=0";
          mkCamera = name: channel: {
            inherit name;
            value = {
              ffmpeg.inputs = [
                {
                  path = rtspUrl channel;
                  roles = [
                    "record"
                  ];
                }
              ];
              detect = {
                width = 1920;
                height = 1080;
              };
            };
          };
        in
        enabled
        // {
          environmentFile = config.sops.secrets.frigate-env.path;
          settings = {
            detect.enabled = false;
            cameras = builtins.listToAttrs [
              (mkCamera "cam1" 1)
              (mkCamera "cam2" 2)
              (mkCamera "cam3" 3)
              (mkCamera "cam4" 4)
            ];
          };
        };

      immich = enabled // {
        backup = enabled;
        mediaDir = "/mnt/photos";
      };

      mealie = enabled;

      miniflux = enabled // {
        proxy = enabled;
      };

      monitoring = enabled // {
        alloy = enabled;
        loki = enabled;
        prometheus = enabled;
      };

      ntopng = enabled;

      nvidia-exporter = enabled;

      paperless = enabled // {
        backup = enabled;
        mediaDir = "/mnt/documents/";
        proxy = enabled;
      };

      postgres = enabled // {
        package = pkgs.postgresql_16;
      };

      restic = enabled;

      ripe-probe = enabled;

      ssh = enabled // {
        addRootKeys = true;
        passwordAuth = false;
        permitRootLogin = true;
      };

      tailscale = enabled // {
        authKeyFile = config.sops.secrets.server-tsauthkey.path;
        ssh = true;
      };
    };

    system.boot = enabled // {
      secure = disabled;
      timeout = 1;
    };

    virtualisation = enabled;
  };

  # Enable passwordless sudo.
  security.sudo.extraRules = [
    {
      users = [ "yash" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services.prometheus = {
    exporters.snmp = enabled // {
      configurationPath = ./snmp.yml;
      port = ports.exporters.snmp;
    };

    scrapeConfigs = [
      {
        job_name = "mikrotik";
        scrape_interval = "30s";
        metrics_path = "/snmp";
        params = {
          module = [ "mikrotik" ];
          auth = [ "homelab_v2" ];
        };
        static_configs = [ { targets = [ "10.0.20.1" ]; } ];
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "127.0.0.1:${toString ports.exporters.snmp}";
          }
        ];
      }
    ];
  };

  systemd.targets.multi-user.enable = true;

  users = {
    mutableUsers = false;
    users.yash = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.user-password.path;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      ignoreShellProgramCheck = true;
    };
  };

  system.stateVersion = "26.05";
}
