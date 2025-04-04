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
in
{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  age.secrets = {
    cloudflared.file = getSecret "cloudflared" hostName;
    homepage.file = getSecret "homepage.env" hostName;
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

  services.caddy = {
    enable = true;
    enableReload = false;
    environmentFile = config.age.secrets.tsauthkey-env.path;
    package = pkgs.${namespace}.caddy-tailscale;
    virtualHosts = {
      "https://dash.turtle-lake.ts.net" = {
        extraConfig = ''
          bind tailscale/homepage
          reverse_proxy :3000
        '';
      };
      "https://analytics.turtle-lake.ts.net" = {
        extraConfig = ''
          bind tailscale/plausible
          reverse_proxy :8181
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

  # TODO: Move this to separate module later.
  services.homepage-dashboard = enabled // {
    environmentFile = config.age.secrets.homepage.path;
    listenPort = 3000;
    openFirewall = true;
    customCSS = ''
      #revalidate { display: none; }
    '';
    settings = {
      title = "Yash's Homelab";
      description = "A collection of services running on my homelab.";
      favicon = "https://yashgarg.dev/favicon.ico";
      theme = "dark";
    };
    bookmarks = [
      {
        Development = [
          {
            Calendar = [
              {
                icon = "si-notion";
                href = "https://calendar.notion.so/";
              }
            ];
          }
          {
            Github = [
              {
                icon = "si-github";
                href = "https://github.com/";
              }
            ];
          }
          {
            "NixOS Search" = [
              {
                icon = "si-nixos";
                href = "https://search.nixos.org/packages";
              }
            ];
          }
          {
            Raindrop = [
              {
                icon = "si-icloud";
                href = "https://app.raindrop.io/";
              }
            ];
          }
        ];
      }
      {
        Social = [
          {
            Reddit = [
              {
                icon = "si-reddit";
                href = "https://reddit.com/";
              }
            ];
          }
          {
            LinkedIn = [
              {
                icon = "si-linkedin";
                href = "https://linkedin.com/";
              }
            ];
          }
          {
            Twitter = [
              {
                icon = "si-twitter";
                href = "https://x.com/";
              }
            ];
          }
          {
            Mastodon = [
              {
                icon = "si-mastodon";
                href = "https://elk.zone/";
              }
            ];
          }
          {
            Pinterest = [
              {
                icon = "si-pinterest";
                href = "https://pinterest.com/";
              }
            ];
          }
        ];
      }
      {
        Entertainment = [
          {
            Netflix = [
              {
                icon = "si-netflix";
                href = "https://netflix.com/";
              }
            ];
          }
          {
            Spotify = [
              {
                icon = "si-spotify";
                href = "https://spotify.com/";
              }
            ];
          }
          {
            "Prime Video" = [
              {
                icon = "si-prime";
                href = "https://primevideo.com/";
              }
            ];
          }
          {
            YouTube = [
              {
                icon = "si-youtube";
                href = "https://youtube.com/";
              }
            ];
          }
        ];
      }
    ];
    services = [
      {
        Utility = [
          {
            "File Browser" = {
              icon = "filebrowser.png";
              href = "{{HOMEPAGE_VAR_FILEBROWSER_URL}}";
              description = "File Browser";
            };
          }
          {
            MiniFlux = {
              icon = "miniflux.png";
              href = "{{HOMEPAGE_VAR_MINIFLUX_URL}}";
              description = "RSS Reader";
              widget = {
                type = "miniflux";
                url = "{{HOMEPAGE_VAR_MINIFLUX_URL}}";
                key = "{{HOMEPAGE_VAR_MINIFLUX_API_KEY}}";
              };
            };
          }
          {
            "Pi-hole" = {
              icon = "pi-hole.png";
              href = "{{HOMEPAGE_VAR_PIHOLE_URL}}/admin/";
              description = "Network Wide Ad Blocker";
              widget = {
                type = "pihole";
                url = "{{HOMEPAGE_VAR_PIHOLE_URL}}";
                version = "6";
                key = "{{HOMEPAGE_VAR_PIHOLE_API_KEY}}";
              };
            };
          }
          {
            Tailscale = {
              icon = "tailscale.png";
              href = "https://login.tailscale.com/admin/machines";
              description = "VPN";
              widget = {
                type = "tailscale";
                deviceid = "{{HOMEPAGE_VAR_TAILSCALE_DEVICE_ID}}";
                key = "{{HOMEPAGE_VAR_TAILSCALE_API_KEY}}";
              };
            };
          }
        ];
      }
      {
        Media = [
          {
            qBitTorrent = {
              icon = "qbittorrent.png";
              href = "{{HOMEPAGE_VAR_QBITTORRENT_URL}}";
              description = "Torrent Client";
              widget = {
                type = "qbittorrent";
                url = "{{HOMEPAGE_VAR_QBITTORRENT_URL}}";
                username = "{{HOMEPAGE_VAR_QBITTORRENT_USERNAME}}";
                password = "{{HOMEPAGE_VAR_QBITTORRENT_PASSWORD}}";
                enableLeechProgress = true;
              };
            };
          }
          {
            Jellyfin = {
              icon = "jellyfin.png";
              href = "{{HOMEPAGE_VAR_JELLYFIN_URL}}";
              description = "Media Server";
              widget = {
                type = "jellyfin";
                url = "{{HOMEPAGE_VAR_JELLYFIN_URL}}";
                key = "{{HOMEPAGE_VAR_JELLYFIN_API_KEY}}";
              };
            };
          }
        ];
      }
      {
        Others = [
          {
            "Actual Budget" = {
              icon = "actual-budget.png";
              href = "{{HOMEPAGE_VAR_ACTUAL_BUDGET_URL}}";
              description = "Budget Tracker";
            };
          }
          {
            Plausible = {
              icon = "plausible.png";
              href = "{{HOMEPAGE_VAR_PLAUSIBLE_URL}}";
              description = "Web Analytics";
            };
          }
          {
            Kener = {
              icon = "uptime-kuma.png";
              href = "{{HOMEPAGE_VAR_KENER_URL}}";
              description = "Status Page";
            };
          }
          {
            "Home Assistant" = {
              icon = "home-assistant.png";
              href = "{{HOMEPAGE_VAR_HOMEASSISTANT_URL}}";
              description = "Home Automation";
              widget = {
                type = "homeassistant";
                url = "{{HOMEPAGE_VAR_HOMEASSISTANT_URL}}";
                key = "{{HOMEPAGE_VAR_HOMEASSISTANT_API_KEY}}";
              };
            };
          }
          {
            Minecraft = {
              icon = "minecraft.png";
              href = "https://map.yashgarg.dev/";
              description = "Minecraft Server";
              widget = {
                type = "minecraft";
                url = "{{HOMEPAGE_VAR_MINECRAFT_URL}}";
              };
            };
          }
        ];
      }
    ];
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
          cputemp = false;
          uptime = false;
          expanded = true;
        };
      }
      {
        openmeteo = {
          label = "Weather";
          latitude = "20.5937";
          longitude = "-78.9629";
          timezone = "Asia/Kolkata";
          units = "metric";
          cache = 5;
          format.maximumFractionDigits = 1;
        };
      }
      {
        search = {
          provider = "google";
          target = "_blank";
        };
      }
    ];
  };

  # Disable autologin.
  services.getty.autologinUser = null;

  systemd.targets.multi-user.enable = true;

  system.stateVersion = "24.11";
}
