{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.linkding;
in
{
  options.${namespace}.services.linkding = {
    enable = mkEnableOption "Easy to use self-hosted bookmark manager";

    port = mkOption {
      type = types.int;
      default = 9090;
      description = "Port on which the linkding will listen";
    };

    proxy = {
      enable = mkEnableOption "Enable the linkding service";
      domain = mkOption {
        type = types.str;
        default = "yashgarg.dev";
        description = "The domain name for the linkding service";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /var/lib/linkding 0750 nobody nogroup -"
    ];

    virtualisation.oci-containers.containers.linkding = {
      image = "sissbruecker/linkding:latest";
      autoStart = true;

      ports = [ "${toString cfg.port}:9090" ];
      volumes = [ "/var/lib/linkding:/app/data" ];
      environment = {
        LD_SUPERUSER_NAME = "yash";
        # change on first run
        LD_SUPERUSER_PASSWORD = "changeme1234";
      };
    };

    services.caddy.virtualHosts = mkIf cfg.proxy.enable {
      "links.${cfg.proxy.domain}" = {
        extraConfig = ''
          import auth
          reverse_proxy 127.0.0.1:${toString cfg.port}
        '';
      };
    };
  };
}
