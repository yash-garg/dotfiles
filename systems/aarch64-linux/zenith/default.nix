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
  get-secret = name: snowfall.fs.get-file "secrets/${hostName}/${name}.age";
in
{
  imports = [ ./hardware-configuration.nix ];

  age.secrets = {
    passwordfile-zenith.file = get-secret "user";
    feed-auth.file = get-secret "miniflux.env";
    tsauthkey.file = get-secret "tailscale";
    tsauthkey-env.file = get-secret "caddy.env";
  };

  boot.tmp.cleanOnBoot = true;
  zramSwap = enabled;

  networking = {
    domain = "";
    inherit hostName;
  };

  dots = {
    server = enabled;

    services = {
      ssh = enabled // {
        addRootKeys = true;
        passwordAuth = false;
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

  users.users.yash = {
    isNormalUser = true;
    hashedPasswordFile = config.age.secrets.passwordfile-zenith.path;
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
    extraGroups = [ "wheel" ];
  };

  system.stateVersion = "24.11";
}
