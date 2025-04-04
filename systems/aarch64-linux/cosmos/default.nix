{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  hostName = "cosmos";
in
{
  imports = [ ./hardware-configuration.nix ];

  age.secrets = {
    passwordfile-cosmos.file = getSecret "user" hostName;
    tsauthkey.file = getSecret "tailscale" hostName;
    tsauthkey-env.file = getSecret "tailscale.env" hostName;
  };

  boot.initrd.systemd.tpm2.enable = mkForce false;

  dots = {
    hardware.networking = enabled // {
      inherit hostName;
      extra = false;
      tcpPorts = [
        80
        90
        443
      ];
    };

    services = {
      avahi = enabled;

      qbittorrent = enabled;

      samba = enabled // {
        shares = {
          media.path = "/mnt/wd500";
          evo.path = "/mnt/evo970";
        };
      };

      ssh = enabled // {
        package = pkgs.openssh_hpn;
        passwordAuth = true;
        permitRootLogin = true;
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

      jellyfin = enabled;
    };

    virtualisation = enabled;
  };

  environment = {
    pathsToLink = [ "/share/bash-completion" ];
    systemPackages = with pkgs; [
      git
      bluez
      bluez-tools
    ];
  };

  services.caddy = {
    enable = true;
    enableReload = false;
    environmentFile = config.age.secrets.tsauthkey-env.path;
    package = pkgs.${namespace}.caddy-tailscale;
    virtualHosts = {
      "https://qbit.turtle-lake.ts.net" = {
        extraConfig = ''
          bind tailscale/qbittorrent
          reverse_proxy :3000
        '';
      };
      "https://jf.turtle-lake.ts.net" = {
        extraConfig = ''
          bind tailscale/jellyfin
          reverse_proxy :8096
        '';
      };
    };
  };

  topology.self.name = "Raspberry Pi 5";

  users = {
    mutableUsers = false;
    users.yash = {
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets.passwordfile-cosmos.path;
      ignoreShellProgramCheck = true;
      extraGroups = [
        "docker"
        "wheel"
      ];
    };
  };

  virtualisation.oci-containers.containers = {
    h5ai = {
      image = "awesometic/h5ai:latest";
      ports = [ "80:80" ];
      volumes = [ "/mnt:/h5ai" ];
      autoStart = true;
    };
  };

  system.stateVersion = "24.11";
}
