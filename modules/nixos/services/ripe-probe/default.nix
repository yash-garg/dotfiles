{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.ripe-probe;
in
{
  options.${namespace}.services.ripe-probe = {
    enable = mkEnableOption "RIPE NCC Probe";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.ripe-probe = {
      image = "jamesits/ripe-atlas:latest";
      autoStart = true;
      environment.RXTXRPT = "yes";
      capabilities = {
        all = false;
        NET_RAW = true;
        KILL = true;
        SETUID = true;
        SETGID = true;
        FOWNER = true;
        CHOWN = true;
        DAC_OVERRIDE = true;
      };
      extraOptions = [
        "--network=host"
        "--hostname=${config.networking.fqdn}"
      ];
      volumes = [
        "/var/lib/ripe-probe/etc:/var/atlas-probe/etc"
        "/var/lib/ripe-probe/status:/var/atlas-probe/status"
      ];
    };
  };
}
