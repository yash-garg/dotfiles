{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.adguard;
in
{
  options.${namespace}.services.adguard = {
    enable = mkEnableOption "Adguard Home Server";
  };

  config = mkIf cfg.enable {
    networking.firewall = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };

    services.adguardhome = enabled // {
      host = "127.0.0.1";
      port = ports.adguard;
      mutableSettings = true;
      openFirewall = true;
      settings = {
        http = {
          address = "127.0.0.1:${toString ports.adguard}";
        };
      };
    };
  };
}
