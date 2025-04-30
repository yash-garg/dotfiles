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
  hostName = "zenith";
  inherit (config.${namespace}.services.tailscale) tailnet;
in
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  age.secrets = {
    user-password.file = getSecret "user" hostName;
    plausible.file = getSecret "plausible" hostName;
    tsauthkey.file = getSecret "tailscale" hostName;
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

    sso = enabled;

    services = {
      gatus = enabled // {
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
      };

      plausible = enabled // {
        baseUrl = domain;
        secretKeybaseFile = config.age.secrets.plausible.path;
      };

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
    };
  };

  services.caddy = enabled // {
    acmeCA = "https://acme-v02.api.letsencrypt.org/directory";
    email = "spam@${domain}";
    enableReload = false;
    logFormat = ''
      output file /var/log/caddy/caddy_main.log {
        roll_size 100MiB
        roll_keep 5
        roll_keep_for 100d
      }
      format json
      level INFO
    '';
    extraConfig = ''
      (auth) {
        forward_auth :9091 {
          uri /api/authz/forward-auth
          copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
        }
      }
    '';
    virtualHosts = {
      "status.${domain}" = {
        extraConfig = ''
          reverse_proxy :3333
        '';
      };
      "unraid.${domain}" = {
        extraConfig = ''
          import auth
          reverse_proxy https://100.78.157.31 {
            transport http {
              tls_insecure_skip_verify
            }
          }
        '';
      };
      "budget.${domain}" = {
        extraConfig = ''
          import auth
          reverse_proxy https://100.78.157.31:5006 {
            transport http {
              tls_insecure_skip_verify
            }
          }
        '';
      };
      "qbit.${domain}" = {
        extraConfig = ''
          import auth
          reverse_proxy 100.78.157.31:8080
        '';
      };
      "stats.${domain}" = {
        extraConfig = ''
          import auth
          reverse_proxy 100.78.157.31:3000
        '';
      };
      "radarr.${domain}" = {
        extraConfig = ''
          import auth
          reverse_proxy 100.78.157.31:7878
        '';
      };
      "prometheus.${domain}" = {
        extraConfig = ''
          import auth
          reverse_proxy 100.78.157.31:9090
        '';
      };
      "cadvisor.${domain}" = {
        extraConfig = ''
          import auth
          reverse_proxy 100.78.157.31:8081
        '';
      };
      "stream.${domain}" = {
        extraConfig = ''
          import auth
          reverse_proxy 100.78.157.31:8096
        '';
      };
      "prowlarr.${domain}" = {
        extraConfig = ''
          import auth
          reverse_proxy 100.78.157.31:9696
        '';
      };
      "sonarr.${domain}" = {
        extraConfig = ''
          import auth
          reverse_proxy 100.78.157.31:8989
        '';
      };
      "rss.${domain}" = {
        extraConfig = ''
          import auth
          reverse_proxy 100.78.157.31:5600
        '';
      };
      "map.${domain}" = {
        extraConfig = ''
          import auth
          reverse_proxy 100.92.154.106:81
        '';
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

  # Disable autologin.
  services.getty.autologinUser = null;

  systemd.targets.multi-user.enable = true;

  system.stateVersion = "24.11";
}
