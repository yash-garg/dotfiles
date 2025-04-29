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
  hostName = "zenith";
  inherit (config.${namespace}.services.tailscale) tailnet;
in
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  age.secrets = {
    cloudflared.file = getSecret "cloudflared" hostName;
    user-password.file = getSecret "user" hostName;
    plausible.file = getSecret "plausible" hostName;
    tsauthkey.file = getSecret "tailscale" hostName;
    tsauthkey-env.file = getSecret "tailscale.env" hostName;
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
    networkmanager = enabled;
    inherit hostName;
  };

  dots = {
    server = enabled;

    services = {
      authelia = enabled;

      ssh = enabled // {
        addRootKeys = true;
        passwordAuth = false;
        permitRootLogin = false;
      };

      tailscale = enabled // {
        authKeyFile = config.age.secrets.tsauthkey.path;
        extraOptions = [
          "--accept-risk=lose-ssh"
          "--advertise-exit-node"
          "--advertise-routes=192.168.0.0/24,192.168.1.0/24"
          "--ssh"
        ];
      };

      plausible = enabled // {
        baseUrl = "analytics.yashgarg.dev";
        secretKeybaseFile = config.age.secrets.plausible.path;
      };
    };

    virtualisation = enabled;
  };

  services = {
    caddy = enabled // {
      enableReload = false;
      environmentFile = config.age.secrets.tsauthkey-env.path;
      package = pkgs.${namespace}.caddy-tailscale;
      logFormat = ''
        output file /var/log/caddy/caddy_main.log {
          roll_size 100MiB
          roll_keep 5
          roll_keep_for 100d
        }
        format json
        level INFO
      '';
      virtualHosts = {
        "https://plausible.${tailnet}" = {
          extraConfig = ''
            bind tailscale/plausible
            reverse_proxy :8181
          '';
        };
      };
    };

    gatus = enabled // {
      settings = {
        web.port = 3333;
        connectivity.checker = {
          target = "1.1.1.1:53";
          interval = "60s";
        };
        ui = {
          title = "Homelab Status | Yash Garg";
          description = "Monitoring for My Services";
          header = "Yash's Homelab Status";
          link = "https://app.yashgarg.dev";
          dark-mode = true;
        };
        endpoints =
          let
            monitorPoints = [
              {
                name = "Actual Budget";
                url = "http://vortex.${tailnet}:5006";
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
                name = "Jellyfin";
                url = "http://nova.${tailnet}:8096";
              }
              {
                name = "Miniflux";
                url = "http://nova.${tailnet}:5600";
              }
              {
                name = "Minecraft Map";
                url = "http://vortex.${tailnet}:81";
              }
              {
                name = "Prometheus";
                url = "http://nova.${tailnet}:9090";
              }
              {
                name = "Plausible Analytics";
                url = "https://plausible.${tailnet}";
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
                name = "Sonarr";
                url = "http://nova.${tailnet}:8989";
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
          in
          map (endpoint: {
            inherit (endpoint) name url;
            ui = {
              hide-conditions = true;
              hide-hostname = true;
              hide-url = true;
            };
            interval = "10m";
            conditions = [
              "[STATUS] == 200"
              "[RESPONSE_TIME] < 500"
            ];
          }) monitorPoints;
      };
    };
  };

  users.users.yash = {
    isNormalUser = true;
    hashedPasswordFile = config.age.secrets.user-password.path;
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

  virtualisation.oci-containers.containers.cloudflared-tunnel = {
    image = "cloudflare/cloudflared:latest";
    cmd = [
      "tunnel"
      "--no-autoupdate"
      "run"
    ];
    extraOptions = [
      "--network"
      "host"
    ];
    environmentFiles = [ config.age.secrets.cloudflared.path ];
  };

  # Disable autologin.
  services.getty.autologinUser = null;

  systemd.targets.multi-user.enable = true;

  system.stateVersion = "24.11";
}
