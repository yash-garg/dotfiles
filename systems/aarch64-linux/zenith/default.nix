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
  domain = "yashgarg.dev";
  homeDomain = "ipx.ovh";
in
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  sops.secrets = {
    user-password = {
      sopsFile = snowfall.fs.get-file "secrets/users.yaml";
      key = config.networking.hostName;
      neededForUsers = true;
    };
    server-tsauthkey.sopsFile = snowfall.fs.get-file "secrets/tailscale.yaml";
    plausible-secret.sopsFile = snowfall.fs.get-file "secrets/plausible.yaml";
  };

  boot = {
    loader = {
      systemd-boot = enabled;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
    initrd.systemd = enabled;
  };

  dots = {
    server = enabled;

    hardware.networking = enabled // {
      hostName = "zenith";
      ports = [
        80
        443
        8080
      ];
    };

    services =
      let
        inherit (config.${namespace}.services.tailscale) tailnet;
        ares = "ares.${tailnet}";
        nova = "nova.${tailnet}";
        quasar = "quasar.${tailnet}";
        vortex = "vortex.${tailnet}";
      in
      {
        actual-budget = enabled // {
          backup = enabled;
          domain = homeDomain;
        };

        atticd = enabled // {
          bucket = "attic-cache";
          endpoint = "https://a69e81e6342baaeed47710799b04477a.r2.cloudflarestorage.com";
        };

        caddy = enabled // {
          domain = homeDomain;
          auth = enabled;
          internal = enabled;
          services = {
            home = {
              domain = homeDomain;
              upstream = "http://homeassistant.${config.${namespace}.services.tailscale.tailnet}:8123";
            };
            unraid = {
              domain = homeDomain;
              upstream = "https://${nova}";
            };
          };
          servers = {
            zenith = {
              address = "http://localhost:${toString ports.caddy}";
              hosts = [
                "cache.${homeDomain}"
                "money.${homeDomain}"
                "git.${homeDomain}"
                "links.${homeDomain}"
                "grafana.${homeDomain}"
                "auth.${homeDomain}"
                "users.${homeDomain}"
                "home.${homeDomain}"
                "notes.${homeDomain}"
                "unraid.${homeDomain}"
                "status.${domain}"
                "analytics.${domain}"
              ];
            };
            quasar = {
              address = "http://[2405:201:4019:7033:cb7f:5f0e:7136:11cd]:${toString ports.caddy}";
              fallback = "http://quasar.${tailnet}:${toString ports.caddy}";
              hosts = [
                "photos.${homeDomain}"
                "books.${homeDomain}"
                "pdf.${homeDomain}"
                "fs.${homeDomain}"
                "meals.${homeDomain}"
                "ntop.${homeDomain}"
                "rss.${homeDomain}"
                "paperless.${homeDomain}"
                "stream.${homeDomain}"
                "qbit.${homeDomain}"
                "radarr.${homeDomain}"
                "sonarr.${homeDomain}"
                "prowlarr.${homeDomain}"
                "bazarr.${homeDomain}"
              ];
            };
            vortex = {
              address = "http://vortex.${tailnet}:${toString ports.caddy}";
              hosts = [ "map.${homeDomain}" ];
            };
          };
        };

        forgejo = enabled // {
          domain = homeDomain;
        };

        gatus = enabled // {
          inherit domain;
          endpoints = {
            actual-budget = {
              name = "Actual Budget";
              group = "BOM";
              url = "http://localhost:${toString ports.actual-budget}";
            };
            atticd = {
              name = "Attic Cache";
              group = "BOM";
              url = "https://cache.${homeDomain}";
            };
            authelia = {
              name = "Authelia";
              group = "BOM";
              url = "http://localhost:${toString ports.authelia}";
            };
            bazarr = {
              name = "Bazarr";
              group = "Homelab";
              url = "http://${quasar}:${toString ports.bazarr}";
            };
            bentopdf = {
              name = "BentoPDF";
              group = "Homelab";
              url = "http://${quasar}:${toString ports.bentopdf}";
            };
            calibre-web = {
              name = "Calibre Web";
              group = "Homelab";
              url = "http://${quasar}:${toString ports.calibre}";
            };
            copyparty = {
              name = "Copyparty";
              group = "Homelab";
              url = "http://${quasar}:${toString ports.copyparty}";
            };
            forgejo = {
              name = "Forgejo";
              group = "BOM";
              url = "http://localhost:${toString ports.forgejo}";
            };
            grafana = {
              name = "Grafana";
              group = "BOM";
              url = "http://localhost:9092";
            };
            home-assistant = {
              name = "Home Assistant";
              group = "Homelab";
              url = "http://homeassistant.${tailnet}:8123";
            };
            immich = {
              name = "Immich";
              group = "Homelab";
              url = "http://${quasar}:${toString ports.immich.webui}";
            };
            jellyfin = {
              name = "Jellyfin";
              group = "Homelab";
              url = "http://${quasar}:${toString ports.jellyfin}";
            };
            linkding = {
              name = "Linkding";
              group = "BOM";
              url = "http://localhost:${toString ports.linkding}";
            };
            lldap = {
              name = "LLDAP";
              group = "BOM";
              url = "http://localhost:${toString ports.lldap}";
            };
            mealie = {
              name = "Mealie";
              group = "Homelab";
              url = "http://${quasar}:${toString ports.mealie}";
            };
            miniflux = {
              name = "Miniflux";
              group = "Homelab";
              url = "http://${quasar}:${toString ports.miniflux}";
            };
            minecraft-server = {
              name = "Minecraft Server";
              group = "BOM";
              url = "udp://${vortex}:${toString ports.minecraft}";
            };
            minecraft-map = {
              name = "Minecraft Map";
              group = "BOM";
              url = "http://${vortex}:${toString ports.pl3xmap}";
            };
            paperless = {
              name = "Paperless NGX";
              group = "Homelab";
              url = "http://${quasar}:${toString ports.paperless-ngx}";
            };
            postgres-primary = {
              name = "PostgreSQL";
              group = "BOM";
              url = "tcp://localhost:${toString ports.postgres}";
            };
            postgres-secondary = {
              name = "PostgreSQL";
              group = "Homelab";
              url = "tcp://${quasar}:${toString ports.postgres}";
            };
            prometheus = {
              name = "Prometheus";
              group = "Homelab";
              url = "http://${quasar}:${toString ports.prometheus}";
            };
            loki = {
              name = "Loki";
              group = "Homelab";
              url = "tcp://${quasar}:${toString ports.loki}";
            };
            ntopng = {
              name = "Ntopng";
              group = "Homelab";
              url = "http://${quasar}:${toString ports.ntopng.webui}";
            };
            alloy = {
              name = "Alloy";
              group = "Homelab";
              url = "http://${quasar}:${toString ports.alloy}";
            };
            caddy = {
              name = "Caddy";
              group = "Homelab";
              url = "tcp://${quasar}:443";
            };
            prowlarr = {
              name = "Prowlarr";
              group = "Homelab";
              url = "http://${quasar}:${toString ports.prowlarr}";
            };
            qbittorrent = {
              name = "qBittorrent";
              group = "Homelab";
              url = "http://${quasar}:${toString ports.qbittorrent.webui}";
            };
            radarr = {
              name = "Radarr";
              group = "Homelab";
              url = "http://${quasar}:${toString ports.radarr}";
            };
            sonarr = {
              name = "Sonarr";
              group = "Homelab";
              url = "http://${quasar}:${toString ports.sonarr}";
            };
            umami = {
              name = "Umami";
              group = "BOM";
              url = "http://localhost:${toString ports.umami}";
            };
            unraid = {
              name = "Unraid";
              group = "Homelab";
              url = "http://${nova}";
            };

            # DEL: ares monitoring and public proxy
            prometheus-ares = {
              name = "Prometheus";
              group = "DEL";
              url = "http://${ares}:${toString ports.prometheus}";
            };
            loki-ares = {
              name = "Loki";
              group = "DEL";
              url = "tcp://${ares}:${toString ports.loki}";
            };
            caddy-ares = {
              name = "Caddy";
              group = "DEL";
              url = "tcp://${ares}:443";
            };
            alloy-ares = {
              name = "Alloy";
              group = "DEL";
              url = "http://${ares}:${toString ports.alloy}";
            };
            proxy-ipv4 = {
              name = "Public Proxy IPv4";
              group = "DEL";
              url = "tcp://139.84.177.122:443";
            };
            proxy-ipv6 = {
              name = "Public Proxy IPv6";
              group = "DEL";
              url = "tcp://[2a0c:9a40:8911::1]:443";
            };

            # BOM: zenith monitoring and public proxy
            prometheus-bom = {
              name = "Prometheus";
              group = "BOM";
              url = "http://localhost:${toString ports.prometheus}";
            };
            loki-bom = {
              name = "Loki";
              group = "BOM";
              url = "tcp://localhost:${toString ports.loki}";
            };
            caddy-bom = {
              name = "Caddy";
              group = "BOM";
              url = "tcp://localhost:443";
            };
            alloy-bom = {
              name = "Alloy";
              group = "BOM";
              url = "http://localhost:${toString ports.alloy}";
            };
          };
        };

        linkding = enabled // {
          database = enabled;
          proxy = enabled // {
            domain = homeDomain;
          };
        };

        monitoring = enabled // {
          domain = homeDomain;
          alloy = enabled;
          grafana = enabled // {
            remoteDatasources = [
              {
                name = "ares";
                ip = "100.105.194.6";
                prometheus = true;
                loki = true;
              }
              {
                name = "quasar";
                ip = "100.93.8.41";
                prometheus = true;
                loki = true;
              }
              {
                name = "vortex";
                ip = "100.65.244.114";
                prometheus = true;
                loki = true;
              }
            ];
          };
          loki = enabled;
          prometheus = enabled;
        };

        postgres = enabled // {
          backup = enabled;
        };

        restic = enabled;

        ssh = enabled // {
          addRootKeys = true;
          passwordAuth = false;
          permitRootLogin = false;
        };

        sso = enabled // {
          domain = homeDomain;
        };

        tailscale = enabled // {
          authKeyFile = config.sops.secrets.server-tsauthkey.path;
          ssh = true;
        };

        umami = enabled // {
          appSecretFile = config.sops.secrets.plausible-secret.path;
          baseUrl = domain;
        };
      };

    virtualisation = enabled;
  };

  services.prometheus.scrapeConfigs = [
    {
      job_name = "bgptools-export";
      scheme = "https";
      metrics_path = "/prom/76dd5676-5af1-4e32-8716-381770873249";
      scrape_interval = "30s";
      static_configs = [
        { targets = [ "prometheus.bgp.tools" ]; }
      ];
    }
  ];

  users.users.yash = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.user-password.path;
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
    extraGroups = [ "wheel" ];
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

  # Disable autologin.
  services.getty.autologinUser = null;

  systemd.targets.multi-user.enable = true;

  system.stateVersion = "26.05";
}
