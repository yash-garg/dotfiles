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
      sopsFile = lib.dots.get-file "secrets/users.yaml";
      key = config.networking.hostName;
      neededForUsers = true;
    };
    server-tsauthkey.sopsFile = lib.dots.get-file "secrets/tailscale.yaml";
    plausible-secret.sopsFile = lib.dots.get-file "secrets/plausible.yaml";
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
        nova = "nova.${tailnet}";
        quasar = "quasar.${tailnet}";
        vortex = "vortex.${tailnet}";
      in
      {
        actual-budget = enabled // {
          backup = enabled;
          domain = homeDomain;
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
                "stats.${domain}"
                "search.${homeDomain}"
              ];
            };
            quasar = {
              address = "http://[2405:201:4019:7033:5054:ff:fed0:31f1]:${toString ports.caddy}";
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
                "nvr.${homeDomain}"
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

        goatcounter = enabled // {
          inherit domain;
        };

        gatus = enabled // {
          inherit domain;
          endpoints = {
            actual-budget = {
              name = "Actual Budget";
              group = "BOM";
              url = "http://localhost:${toString ports.actual-budget}";
            };
            authelia = {
              name = "Authelia";
              group = "BOM";
              url = "http://localhost:${toString ports.authelia}";
            };
            bazarr = {
              name = "Bazarr";
              group = "DEL";
              url = "http://${quasar}:${toString ports.bazarr}";
            };
            bentopdf = {
              name = "BentoPDF";
              group = "DEL";
              url = "http://${quasar}:${toString ports.bentopdf}";
            };
            calibre-web = {
              name = "Calibre Web";
              group = "DEL";
              url = "http://${quasar}:${toString ports.calibre}";
            };
            copyparty = {
              name = "Copyparty";
              group = "DEL";
              url = "http://${quasar}:${toString ports.copyparty}";
            };
            forgejo = {
              name = "Forgejo";
              group = "BOM";
              url = "http://localhost:${toString ports.forgejo}";
            };
            goatcounter = {
              name = "GoatCounter";
              group = "BOM";
              url = "http://localhost:${toString ports.goatcounter}";
            };
            grafana = {
              name = "Grafana";
              group = "BOM";
              url = "http://localhost:${toString ports.grafana}";
            };
            hister = {
              name = "Hister";
              group = "BOM";
              url = "http://localhost:${toString ports.hister}";
            };
            home-assistant = {
              name = "Home Assistant";
              group = "DEL";
              url = "http://homeassistant.${tailnet}:8123";
            };
            immich = {
              name = "Immich";
              group = "DEL";
              url = "http://${quasar}:${toString ports.immich.webui}";
            };
            jellyfin = {
              name = "Jellyfin";
              group = "DEL";
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
            redis-authelia = {
              name = "Redis";
              group = "BOM";
              url = "tcp://localhost:${toString ports.redis.authelia}";
            };
            mealie = {
              name = "Mealie";
              group = "DEL";
              url = "http://${quasar}:${toString ports.mealie}";
            };
            miniflux = {
              name = "Miniflux";
              group = "DEL";
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
              group = "DEL";
              url = "http://${quasar}:${toString ports.paperless-ngx}";
            };
            postgres-primary = {
              name = "PostgreSQL";
              group = "BOM";
              url = "tcp://localhost:${toString ports.postgres}";
            };
            postgres-secondary = {
              name = "PostgreSQL";
              group = "DEL";
              url = "tcp://${quasar}:${toString ports.postgres}";
            };
            prometheus = {
              name = "Prometheus";
              group = "DEL";
              url = "http://${quasar}:${toString ports.prometheus}";
            };
            loki = {
              name = "Loki";
              group = "DEL";
              url = "tcp://${quasar}:${toString ports.loki}";
            };
            ntopng = {
              name = "Ntopng";
              group = "DEL";
              url = "http://${quasar}:${toString ports.ntopng.webui}";
            };
            alloy = {
              name = "Alloy";
              group = "DEL";
              url = "http://${quasar}:${toString ports.alloy}";
            };
            caddy = {
              name = "Caddy";
              group = "DEL";
              url = "tcp://${quasar}:443";
            };
            quasar-wan-ipv6 = {
              name = "WAN IPv6";
              group = "DEL";
              url = "tcp://[2405:201:4019:7033:5054:ff:fed0:31f1]:${toString ports.caddy}";
            };
            prowlarr = {
              name = "Prowlarr";
              group = "DEL";
              url = "http://${quasar}:${toString ports.prowlarr}";
            };
            qbittorrent = {
              name = "qBittorrent";
              group = "DEL";
              url = "http://${quasar}:${toString ports.qbittorrent.webui}";
            };
            radarr = {
              name = "Radarr";
              group = "DEL";
              url = "http://${quasar}:${toString ports.radarr}";
            };
            sonarr = {
              name = "Sonarr";
              group = "DEL";
              url = "http://${quasar}:${toString ports.sonarr}";
            };
            umami = {
              name = "Umami";
              group = "BOM";
              url = "http://localhost:${toString ports.umami}";
            };
            unraid = {
              name = "Unraid";
              group = "DEL";
              url = "http://${nova}";
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

        hister = enabled // {
          domain = homeDomain;
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
