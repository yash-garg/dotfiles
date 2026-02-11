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
  };

  boot.loader.grub = enabled // {
    device = "/dev/vda";
  };

  # Static IP configuration for Vultr VPS
  networking = {
    useDHCP = lib.mkForce false;
    interfaces.ens3 = {
      ipv4.addresses = [
        {
          address = "139.84.177.122";
          prefixLength = 23;
        }
      ];
      ipv6.addresses = [
        {
          address = "2401:c080:3400:224f:5400:05ff:feef:f172";
          prefixLength = 64;
        }
      ];
    };
    defaultGateway = "139.84.176.1";
    defaultGateway6 = {
      address = "fe80::fc00:5ff:feef:f172";
      interface = "ens3";
    };
  };

  dots = {
    hardware.networking = enabled // {
      inherit hostName;
      extra = true;
    };

    services = {
      bird = enabled // {
        routerId = "139.84.177.122";
        bgpPeers = [
          {
            name = "vultr";
            export = "all";
            localAs = 201349;
            remoteAs = 64515;
            multihop = 2;
            neighborAddress = "2001:19f0:ffff::1";
            sourceAddress = "2401:c080:3400:224f:5400:05ff:feef:f172";
            gracefulRestart = true;
            password = "YOUR_PASSWORD_HERE";
          }
        ];
        staticRoutes = [
          {
            prefix = "2a0c:9a40:8910::/44";
            type = "blackhole";
          }
        ];
      };

      ssh = enabled // {
        addRootKeys = true;
      };

      tailscale = enabled // {
        authKeyFile = config.sops.secrets.server-tsauthkey.path;
        exitNode = true;
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
