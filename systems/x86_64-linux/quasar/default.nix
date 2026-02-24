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
      sopsFile = snowfall.fs.get-file "secrets/users.yaml";
      key = hostName;
      neededForUsers = true;
    };
    server-tsauthkey.sopsFile = snowfall.fs.get-file "secrets/tailscale.yaml";
    wireguard-key = {
      sopsFile = snowfall.fs.get-file "secrets/wireguard.yaml";
      key = "quasar-privkey";
      mode = "0400";
    };
    frigate-env = {
      sopsFile = snowfall.fs.get-file "secrets/frigate.env";
      format = "dotenv";
      mode = "0400";
    };
  };

  networking.wg-quick.interfaces.wg0 = {
    address = [
      "fd00:100::4/64"
      "2a0c:9a40:8912::1/64"
    ];
    mtu = 1420;
    privateKeyFile = config.sops.secrets.wireguard-key.path;
    peers = [
      {
        publicKey = "XPTZ/mSeFBK7ekDSX/FjqJ411MWQB+M59SKbO/wjyUU=";
        endpoint = "139.84.177.122:${toString ports.wireguard}";
        allowedIPs = [
          "fd00:100::/64"
          "2a0c:9a40:8911::/48"
          "2a0c:9a40:8913::/48"
          "2a0c:9a40:8914::/48"
        ];
        persistentKeepalive = 25;
      }
    ];
  };

  dots = {
    server = enabled;

    hardware.networking = enabled // {
      inherit hostName;
      ports = [
        22 # SSH only - 80/443 not needed, traffic comes through internal port from Ares
      ];
    };

    services = {
      arr-stack = enabled // {
        mediaDirs = [
          "/mnt/media/main"
          "/mnt/media/samsung"
          "/mnt/media/wd"
        ];
      };

      bentopdf = enabled;

      caddy = enabled // {
        auth = enabled // {
          url = "http://zenith.turtle-lake.ts.net:${toString ports.authelia}";
        };
        internal = enabled // {
          trustedProxies = [
            "2a0c:9a40:8911::/48" # Ares IPv6 prefix
            "139.84.177.122/32" # Ares IPv4
            "fd00:100::/64" # WireGuard internal
          ];
        };
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
          "mnt-media-wd.mount"
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
            "rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@10.0.0.53:554/cam/realmonitor?channel=${toString channel}&subtype=0";
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
        disabled
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
      configuration = {
        auths.homelab_auth = {
          community = "homelab";
          version = 2;
        };
        modules.mikrotik = {
          walk = [
            "1.3.6.1.2.1.2" # ifTable (basic interface info)
            "1.3.6.1.2.1.31.1" # ifXTable (64-bit counters, HC counters)
            "1.3.6.1.2.1.25.1" # hrSystem (uptime, date)
            "1.3.6.1.2.1.25.2" # hrStorage (memory, disk usage)
            "1.3.6.1.2.1.25.3" # hrDevice (CPU load)
            "1.3.6.1.2.1.1" # sysDescr, sysUpTime, sysName, etc.
            "1.3.6.1.4.1.14988.1.1.1" # mtxrSystem (firmware, board name, license)
            "1.3.6.1.4.1.14988.1.1.3" # mtxrHealth (CPU temp, voltage, fan)
            "1.3.6.1.4.1.14988.1.1.7" # mtxrWireless (wireless stats, if applicable)
            "1.3.6.1.4.1.14988.1.1.14" # mtxrDHCP (DHCP lease count)
            "1.3.6.1.4.1.14988.1.1.16" # mtxrInterfaceStats (per-interface bytes)
          ];
        };
      };
      port = ports.exporters.snmp;
    };

    scrapeConfigs = [
      {
        job_name = "mikrotik-snmp";
        scrape_interval = "60s";
        metrics_path = "/snmp";
        params = {
          module = [ "mikrotik" ];
          auth = [ "homelab_auth" ];
          target = [ "10.0.0.1" ];
        };
        static_configs = [
          { targets = [ "127.0.0.1:${toString ports.exporters.snmp}" ]; }
        ];
        relabel_configs = [
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
