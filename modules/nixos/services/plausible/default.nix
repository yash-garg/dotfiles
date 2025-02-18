{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.plausible;
in
{
  options.${namespace}.services.plausible = {
    enable = mkEnableOption "Enable plausible analytics";

    baseUrl = mkOption {
      type = types.str;
      default = "plausible.yashgarg.dev";
      description = "Base URL for the plausible server";
    };

    secretKeybaseFile = mkOption {
      type = types.path;
      default = null;
      description = "Path to a file containing a Tailscale authkey that this device can use to authenticate itself";
    };

    openFirewall = mkBoolOpt true "Open firewall for Plausible";

    port = mkOption {
      type = types.int;
      default = 8181;
      description = "Port on which the plausible server will listen";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    services.plausible = enabled // {
      server = {
        baseUrl = "https://${cfg.baseUrl}";
        disableRegistration = "invite_only";
        port = cfg.port;
        secretKeybaseFile = cfg.secretKeybaseFile;
      };
    };
  };
}
