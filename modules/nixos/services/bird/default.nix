{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.bird;
in
{
  options.${namespace}.services.bird = {
    enable = mkEnableOption "Bird: Internet Routing Daemon";
    routerId = mkOpt types.str "192.0.2.1" "Router ID for Bird (typically your main IPv4 address)";
    extraConfig = mkOpt types.lines "" "Additional Bird configuration";
  };

  config = mkIf cfg.enable {
    services.bird = enabled // {
      autoReload = true;
      checkConfig = false;
      config = ''
        log syslog all;

        router id ${cfg.routerId};

        protocol kernel {
          ipv6 {
            import none;
            export none;
          };
        }

        protocol device {
        }

        ${cfg.extraConfig}
      '';
    };
  };
}
