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
    };
  };

  environment = {
    pathsToLink = [ "/share/bash-completion" ];
    systemPackages = with pkgs; [
      git
      bluez
      bluez-tools
    ];
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

  system.stateVersion = "24.11";
}
