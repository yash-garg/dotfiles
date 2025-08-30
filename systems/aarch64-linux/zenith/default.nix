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
  hostName = "zenith";
  inherit (config.${namespace}.services.tailscale) tailnet;
in
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  sops.secrets = {
    cf-tokens = {
      sopsFile = snowfall.fs.get-file "secrets/cloudflare.env";
      format = "dotenv";
      owner = config.services.traefik.group;
    };

    user-password = {
      sopsFile = snowfall.fs.get-file "secrets/users.yaml";
      key = hostName;
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

  networking = {
    domain = "";
    firewall.allowedTCPPorts = [
      80
      443
    ];
    networkmanager = enabled;
    inherit hostName;
  };

  dots = {
    server = enabled;

    sso = enabled // {
      domain = homeDomain;
    };

    services = {
      actual-budget = enabled // {
        domain = homeDomain;
      };

      gatus = enabled // {
        inherit domain;
        monitorPoints = [
          {
            name = "Actual Budget";
            group = "external";
            url = "http://localhost:3000";
          }
          {
            name = "Adguard";
            url = "http://adguard.${tailnet}";
          }
          {
            name = "Cadvisor";
            url = "http://nova.turtle-lake.ts.net";
          }
          {
            name = "Grafana";
            url = "http://nova.${tailnet}:3000";
          }
          {
            name = "Home Assistant";
            url = "http://homeassistant.${tailnet}:8123";
          }
          {
            name = "Immich";
            url = "http://nova.${tailnet}:8086";
          }
          {
            name = "Jellyfin";
            url = "http://nova.${tailnet}:8096";
          }
          {
            name = "Kavita";
            url = "http://nova.${tailnet}:5000";
          }
          {
            name = "Linkding";
            group = "external";
            url = "http://localhost:9095";
          }
          {
            name = "Mazanoke";
            url = "http://nova.${tailnet}:3474";
          }
          {
            name = "Miniflux";
            url = "http://nova.${tailnet}:5600";
          }
          {
            name = "Minecraft Map";
            group = "external";
            url = "http://vortex.${tailnet}:81";
          }
          {
            name = "Paperless";
            url = "http://nova.${tailnet}:8010";
          }
          {
            name = "Prometheus";
            url = "http://nova.${tailnet}:9090";
          }
          {
            name = "Plausible Analytics";
            group = "external";
            url = "http://localhost:8181";
          }
          {
            name = "Prowlarr";
            url = "http://nova.${tailnet}:9696";
          }
          {
            name = "Radarr";
            url = "http://nova.${tailnet}:7878";
          }
          {
            name = "Readarr";
            url = "http://nova.${tailnet}:8787";
          }
          {
            name = "Sonarr";
            url = "http://nova.${tailnet}:8989";
          }
          {
            name = "Stirling PDF";
            group = "external";
            url = "http://nova.${tailnet}:8087";
          }
          {
            name = "qBittorrent";
            url = "http://nova.${tailnet}:8080";
          }
          {
            name = "unRAID";
            url = "http://nova.${tailnet}";
          }
        ];
      };

      linkding = enabled // {
        database = enabled;
        proxy = enabled // {
          domain = homeDomain;
        };
      };

      plausible = enabled // {
        baseUrl = domain;
        secretKeybaseFile = config.sops.secrets.plausible-secret.path;
      };

      restic = enabled // {
        host = hostName;
      };

      ssh = enabled // {
        addRootKeys = true;
        passwordAuth = false;
        permitRootLogin = false;
      };

      tailscale = enabled // {
        authKeyFile = config.sops.secrets.server-tsauthkey.path;
        exitNode = true;
        ssh = true;
        subnetRouting = enabled // {
          routes = [
            "192.168.0.0/24"
            "192.168.1.0/24"
          ];
        };
      };

      traefik = enabled // {
        domain = homeDomain;
        environmentFiles = [ config.sops.secrets.cf-tokens.path ];
        services =
          let
            nova = "100.78.157.31";
          in
          {
            cadvisor.url = "http://${nova}:8081";

            dns.url = "http://100.93.246.1";

            home.url = "http://100.65.53.36:8123";

            image.url = "http://${nova}:3474";

            map.url = "http://100.92.154.106:81";

            paperless = {
              url = "http://${nova}:8010";
              useAuth = false;
            };

            pdf = {
              url = "http://${nova}:8087";
              useAuth = false;
            };

            photos = {
              url = "http://${nova}:8086";
              useAuth = false;
            };

            prometheus.url = "http://${nova}:9090";

            prowlarr.url = "http://${nova}:9696";

            qbit.url = "http://${nova}:8080";

            read.url = "http://${nova}:5000";

            readarr.url = "http://${nova}:8787";

            restic.url = "http://${nova}:9898";

            radarr.url = "http://${nova}:7878";

            rss = {
              url = "http://${nova}:5600";
              useAuth = false;
            };

            sonarr.url = "http://${nova}:8989";

            stats.url = "http://${nova}:3000";

            stream = {
              url = "http://${nova}:8096";
              useAuth = false;
              middlewares = [ "jellyfin-redirect" ];
            };

            unraid = {
              url = "https://${nova}";
              useInsecure = true;
            };
          };
      };
    };

    virtualisation = enabled;
  };

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

  system.stateVersion = "24.11";
}
