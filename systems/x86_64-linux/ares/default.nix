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
    user-password = {
      sopsFile = snowfall.fs.get-file "secrets/users.yaml";
      key = hostName;
      neededForUsers = true;
    };

    server-tsauthkey.sopsFile = snowfall.fs.get-file "secrets/tailscale.yaml";
    cf-api-token = {
      sopsFile = snowfall.fs.get-file "secrets/cloudflare.env";
      format = "dotenv";
      owner = "caddy";
      group = "caddy";
    };
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
            password "YOUR_PASSWORD_HERE";
          }
        '';
      };

      ssh = enabled // {
        addRootKeys = true;
      };

      tailscale = enabled // {
        authKeyFile = config.sops.secrets.server-tsauthkey.path;
        acceptRoutes = true;
        ssh = true;
      };

      caddy = enabled // {
        environmentFile = config.sops.secrets.cf-api-token.path;
        servers = {
          zenith = {
            primary = "[2603:c021:4006:a800:0:dd78:b386:aace]:443";
            fallback = "[zenith.your-tailnet.ts.net]:443";
            services = [
              "cache"
              "money"
              "git"
              "links"
              "grafana"
              "auth"
              "users"
              "status"
              "analytics"
            ];
          };
          quasar = {
            primary = "[2603:c021:4006:a800:0:dd78:b386:aace]:443";
            fallback = "[quasar.your-tailnet.ts.net]:443";
            services = [
              "photos"
              "books"
              "pdf"
              "fs"
              "meals"
              "rss"
              "paperless"
              "stream"
              "qbit"
              "radarr"
              "sonarr"
              "prowlarr"
              "bazarr"
            ];
          };
        };
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
