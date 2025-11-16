{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.stirling-pdf;
in
{
  options.${namespace}.services.stirling-pdf = {
    enable = mkEnableOption "Stirling PDF";
    port = mkOpt types.int ports.stirling-pdf "The port for the Stirling PDF service";
  };

  config = mkIf cfg.enable {
    services.stirling-pdf = enabled // {
      environment = {
        DOCKER_ENABLE_SECURITY = "false";
        METRICS_ENABLED = "true";
        SERVER_PORT = toString cfg.port;
        SYSTEM_GOOGLEVISIBILITY = "false";
      };
    };
  };
}
