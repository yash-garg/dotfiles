{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  srv = config.${namespace}.services;
  cfg = srv.bentopdf;
in
{
  options.${namespace}.services.bentopdf = {
    enable = mkEnableOption "BentoPDF: A Privacy First PDF Toolkit";
    domain = mkOpt types.str "ipx.ovh" "The domain name for the BentoPDF service";
    port = mkOpt types.int ports.bentopdf "The port for the BentoPDF service";
    version = mkOpt types.str "v2.8.0" "The version of the BentoPDF service";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      bentopdf = {
        image = "bentopdf/bentopdf-simple:${cfg.version}";
        autoStart = true;
        ports = [ "${toString cfg.port}:8080" ];
        environment = {
          TZ = "Asia/Kolkata";
        };
      };
    };

    dots.services.caddy.services.pdf = {
      inherit (cfg) domain;
      upstream = "localhost:${toString cfg.port}";
      auth = false;
    };
  };
}
