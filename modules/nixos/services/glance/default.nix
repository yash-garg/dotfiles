{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.glance;
in
{
  options.${namespace}.services.glance = {
    enable = mkEnableOption "Glance: A self-hosted dashboard";
    settings =
      mkOpt types.attrs { }
        "Configuration for glance (see https://github.com/glanceapp/glance)";
    openFirewall = mkBoolOpt true "Open firewall for glance";
  };

  config = mkIf cfg.enable {
    services.glance = enabled // {
      inherit (cfg) openFirewall;
      settings = mkMerge [
        {
          server = {
            host = "0.0.0.0";
            port = ports.glance;
          };
        }
        cfg.settings
      ];
    };
  };
}
