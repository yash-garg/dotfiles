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

  services.caddy = enabled // {
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
      "https://plausible.turtle-lake.ts.net" = {
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

  # Disable autologin.
  services.getty.autologinUser = null;

  systemd.targets.multi-user.enable = true;

  system.stateVersion = "24.11";
}
