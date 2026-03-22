{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  hostName = "ares";
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  sops.secrets = {
    bgp-password = {
      reloadUnits = [ config.systemd.services.bird.name ];
      sopsFile = snowfall.fs.get-file "secrets/bird.yaml";
      key = "vultr_bgp_password";
      owner = config.systemd.services.bird.serviceConfig.User;
    };
    user-password = {
      sopsFile = snowfall.fs.get-file "secrets/users.yaml";
      key = hostName;
      neededForUsers = true;
    };
    server-tsauthkey.sopsFile = snowfall.fs.get-file "secrets/tailscale.yaml";
    wireguard-key = {
      sopsFile = snowfall.fs.get-file "secrets/wireguard.yaml";
      key = "ares-privkey";
      mode = "0400";
    };
  };

  boot.loader.grub = enabled // {
    device = "/dev/vda";
  };

  networking.wg-quick.interfaces.wg0 = {
    address = [ "fd00:100::1/64" ];
    mtu = 1420;
    listenPort = ports.wireguard;
    privateKeyFile = config.sops.secrets.wireguard-key.path;
    peers = [
      {
        publicKey = "EJ1bNmnxfXLZkWvwnhj8IsuXyuDrfg8c5wOH8YQVo1Y="; # quasar
        allowedIPs = [
          "fd00:100::4/128"
          "2a0c:9a40:8912::/48"
        ];
      }
      {
        publicKey = "PNrL8QIKxJTDE4WWwOrz+aj8YonWkCbDmrUDUO1D5xk="; # vortex
        allowedIPs = [
          "fd00:100::2/128"
          "2a0c:9a40:8913::/48"
        ];
      }
      {
        publicKey = "7tP8xwL3/4qWhNzL0l7hRlHvCqIC1TnvUMY0Cj1CARw="; # zenith
        allowedIPs = [
          "fd00:100::3/128"
          "2a0c:9a40:8914::/48"
        ];
      }
      {
        publicKey = "M7aq0j2aOz2AUoFWpi7uorN0jsFqp5tJgGoUxQTwC1s="; # glinet
        allowedIPs = [
          "fd00:100::5/128"
          "2a0c:9a40:8911:1::/64"
        ];
      }
      {
        publicKey = "BjR9Cnlj+ky491Ysru4yLUIdKx3Gizzh74r95ZLMpSY="; # mikrotik
        allowedIPs = [
          "fd00:100::6/128"
          "2a0c:9a40:8915::/48"
        ];
      }
    ];
  };

  dots = {
    server = enabled;

    hardware.networking = enabled // {
      inherit hostName;
      ports = [
        80
        443
        8080
      ];
      interfaces.ens3 = {
        ipv4 = [ "139.84.177.122/23" ];
        ipv6 = [
          "2401:c080:3400:224f:5400:05ff:feef:f172/64"
          "2a0c:9a40:8911:0::1/64"
        ];
        routes = [
          "0.0.0.0/0 via 139.84.176.1"
        ];
      };
      gateway = "139.84.176.1";
      gateway6 = "fe80::fc00:5ff:feef:f172 ens3";
    };

    services = {
      bird = enabled // {
        routerId = "139.84.177.122";
        extraConfig = ''
          protocol static {
            ipv6;
            route 2a0c:9a40:8911::/48 blackhole;
            route 2a0c:9a40:8911:1::/64 via "wg0";
            route 2a0c:9a40:8912::/48 via "wg0";
            route 2a0c:9a40:8913::/48 via "wg0";
            route 2a0c:9a40:8914::/48 via "wg0";
            route 2a0c:9a40:8915::/48 via "wg0";
          }

          include "${config.sops.secrets.bgp-password.path}";
          protocol bgp vultr {
            local as 201349;
            source address 2401:c080:3400:224f:5400:05ff:feef:f172;
            ipv6 {
              import filter {
                if net = ::/0 then accept;
                reject;
              };

              export filter {
                if net ~ [
                  2a0c:9a40:8911::/48,
                  2a0c:9a40:8912::/48,
                  2a0c:9a40:8913::/48,
                  2a0c:9a40:8914::/48,
                  2a0c:9a40:8915::/48
                ] then accept;
                reject;
              };

              import limit 6;
              export limit 6;
            };
            graceful restart on;
            multihop 2;
            neighbor 2001:19f0:ffff::1 as 64515;
            password BGP_PASSWD;
          }
        '';
      };

      caddy = enabled // {
        servers = {
          zenith = {
            address = "http://[2a0c:9a40:8914::1]:${toString ports.caddy}";
            fallback = "http://[fd7a:115c:a1e0::1901:432c]:${toString ports.caddy}";
            hosts = [
              "cache.ipx.ovh"
              "money.ipx.ovh"
              "git.ipx.ovh"
              "links.ipx.ovh"
              "grafana.ipx.ovh"
              "auth.ipx.ovh"
              "users.ipx.ovh"
              "home.ipx.ovh"
              "notes.ipx.ovh"
              "unraid.ipx.ovh"
              "status.yashgarg.dev"
              "analytics.yashgarg.dev"
            ];
          };
          quasar = {
            address = "http://[2405:201:4019:7033:cb7f:5f0e:7136:11cd]:${toString ports.caddy}";
            fallback = "http://[2a0c:9a40:8912::1]:${toString ports.caddy}";
            hosts = [
              "photos.ipx.ovh"
              "books.ipx.ovh"
              "pdf.ipx.ovh"
              "fs.ipx.ovh"
              "meals.ipx.ovh"
              "ntop.ipx.ovh"
              "rss.ipx.ovh"
              "paperless.ipx.ovh"
              "stream.ipx.ovh"
              "qbit.ipx.ovh"
              "radarr.ipx.ovh"
              "sonarr.ipx.ovh"
              "prowlarr.ipx.ovh"
              "bazarr.ipx.ovh"
            ];
          };
          vortex = {
            address = "http://[2a0c:9a40:8913::1]:${toString ports.caddy}";
            fallback = "http://[fd7a:115c:a1e0::fb01:f473]:${toString ports.caddy}";
            hosts = [ "map.ipx.ovh" ];
          };
        };
      };

      monitoring = enabled // {
        alloy = enabled;
        loki = enabled;
        prometheus = enabled;
      };

      ssh = enabled // {
        addRootKeys = true;
        openFirewall = false;
      };

      tailscale = enabled // {
        authKeyFile = config.sops.secrets.server-tsauthkey.path;
        ssh = true;
      };
    };
  };

  users.users.yash = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.user-password.path;
    ignoreShellProgramCheck = true;
    extraGroups = [ "wheel" ];
  };

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

  system.stateVersion = "26.05";
}
