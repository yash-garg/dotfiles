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
  };

  boot.loader.grub = enabled // {
    device = "/dev/vda";
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
          "2a0c:9a40:8911::1/48"
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
            route 2a0c:9a40:8912::/48 blackhole;
            route 2a0c:9a40:8913::/48 blackhole;
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
                  2a0c:9a40:8913::/48
                ] then accept;
                reject;
              };

              import limit 5;
              export limit 5;
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
            address = "[2603:c021:4006:a800:0:dd78:b386:aace]:443";
            fallback = "[fd7a:115c:a1e0::1901:432c]:443";
            hosts = [
              "cache.ipx.ovh"
              "money.ipx.ovh"
              "git.ipx.ovh"
              "links.ipx.ovh"
              "grafana.ipx.ovh"
              "auth.ipx.ovh"
              "users.ipx.ovh"
              "home.ipx.ovh"
              "unraid.ipx.ovh"
              "status.yashgarg.dev"
              "analytics.yashgarg.dev"
            ];
          };
          quasar = {
            # address = "[2405:201:4019:70a6:3880:1948:620b:354e]:443";
            address = "[fd7a:115c:a1e0::8601:831]:443";
            fallback = null;
            hosts = [
              "photos.ipx.ovh"
              "books.ipx.ovh"
              "pdf.ipx.ovh"
              "fs.ipx.ovh"
              "meals.ipx.ovh"
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
            address = "[2603:c021:400a:2a00:0:d199:f3c0:ff54]:443";
            fallback = "[fd7a:115c:a1e0::fb01:f473]:443";
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
      };

      tailscale = enabled // {
        authKeyFile = config.sops.secrets.server-tsauthkey.path;
        acceptRoutes = true;
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
