{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.golink;
in
{
  options.${namespace}.services.golink = {
    enable = mkEnableOption "golink: private shortlink service for tailnets";
  };

  config = mkIf cfg.enable {
    sops.secrets.golink-tsauthkey = {
      sopsFile = snowfall.fs.get-file "secrets/tailscale.yaml";
      owner = config.services.golink.user;
      restartUnits = [ "golink.service" ];
    };

    services.golink = enabled // {
      tailscaleAuthKeyFile = config.sops.secrets.golink-tsauthkey.path;
    };
  };
}
