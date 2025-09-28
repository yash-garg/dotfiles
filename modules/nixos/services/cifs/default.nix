{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.cifs;
  cifsShare = path: {
    device = "//${path}";
    fsType = "cifs";
    options =
      let
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      in
      [ "${automount_opts},credentials=/etc/nixos/smb-secrets" ];
  };
in
{
  options.${namespace}.services.cifs = {
    enable = mkEnableOption "CIFS Shares Auto-Mounting";
    cifsHost = mkOpt types.str "nova" "The key name for cifs credentials";
    mounts = mkOpt (types.attrsOf (
      types.submodule {
        options = {
          path = mkOpt types.str null "The CIFS share path in the format <hostname>/<share>.";
        };
      }
    )) { } "List of CIFS shares to be mounted.";
  };

  config = mkIf cfg.enable {
    sops.secrets.cifs-env = {
      sopsFile = snowfall.fs.get-file "secrets/cifs.env";
      format = "dotenv";
    };

    environment.etc."nixos/smb-secrets" = {
      source = config.sops.secrets.cifs-env.path;
      mode = "0600";
    };

    environment.systemPackages = [ pkgs.cifs-utils ];

    fileSystems = listToAttrs (
      mapAttrsToList (name: mount: {
        name = "/mnt/${name}";
        value = cifsShare mount.path;
      }) cfg.mounts
    );
  };
}
