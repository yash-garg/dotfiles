{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  hostName = "apollo";
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
  };

  boot.loader.grub = enabled // {
    device = "/dev/sda";
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
      interfaces = {
        ens18 = {
          ipv4 = [ "118.91.187.146/32" ];
          ipv6 = [ "2a0c:9a40:2711:111::1001/64" ];
          routes = [
            "118.91.187.129/32"
            "0.0.0.0/0 via 118.91.187.129"
          ];
        };
        ens19.ipv6 = [ "2001:7f8:ca:1::20:1349:1/64" ];
      };
    };

    services = {
      bird = enabled // {
        routerId = "118.91.187.146";
        extraConfig = ''
          protocol bgp ifog {
            local as 201349;
            neighbor 2a0c:9a40:2711:111::1 as 34927;
            source address 2a0c:9a40:2711:111::1001;
            graceful restart on;
            ipv6 {
              import filter {
                if net = ::/0 then accept;
                reject;
              };
              export filter {
                if net = 2a0c:9a40:8910::/44 then accept;
                reject;
              };
              export limit 5;
              import limit 10;
            };
          }

          protocol bgp fogixp_rs1 {
            local as 201349;
            neighbor 2001:7f8:ca:1::111 as 47498;
            source address 2001:7f8:ca:1::20:1349:1;

            ipv6 {
              import all;
              export filter {
                if net = 2a0c:9a40:8910::/44 then {
                  bgp_large_community.add((47498, 1000, 0));
                  bgp_community.add((65535, 65281));
                  accept;
                }
                reject;
              };
              import limit 200000;
              export limit 5;
            };
          }

          protocol bgp fogixp_rs2 {
            local as 201349;
            neighbor 2001:7f8:ca:1::222 as 47498;
            source address 2001:7f8:ca:1::20:1349:1;

            ipv6 {
              import all;
              export filter {
                if net = 2a0c:9a40:8910::/44 then {
                  bgp_large_community.add((47498, 1000, 0));
                  accept;
                }
                reject;
              };
              import limit 200000;
              export limit 5;
            };
          }

          protocol static {
            ipv6;
            route 2a0c:9a40:8910::/44 blackhole;
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
    };
  };

  users.users.yash = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.user-password.path;
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

  system.stateVersion = "26.05";
}
