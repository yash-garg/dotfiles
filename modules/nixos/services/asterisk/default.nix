{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.asterisk;

  # Private configuration stays encrypted as complete files.
  confFiles = {
    pjsip = "pjsip.conf";
    pjsip-jio = "pjsip_jio.conf";
    extensions = "extensions.conf";
  };
in
{
  options.${namespace}.services.asterisk = {
    enable = mkEnableOption "Asterisk PBX with JioFiber SIP trunk";

    domain =
      mkOpt types.str "yashgarg.dev"
        "Domain for the public SIP WebSocket endpoint (sip.<domain>)";
  };

  config = mkIf cfg.enable {
    # Keep credentials, line identities, and private addresses out of the Nix store.
    sops.secrets = mapAttrs' (
      key: file:
      nameValuePair "asterisk/${key}" {
        sopsFile = lib.dots.get-file "secrets/asterisk.yaml";
        inherit key;
        path = "/etc/asterisk/${file}";
        owner = "asterisk";
      }
    ) confFiles;

    # Ensure /etc/asterisk/ exists before sops activation writes into it
    environment.etc."asterisk/.keep".text = "";

    networking.firewall = {
      allowedUDPPorts = [ 5060 ];
      allowedTCPPorts = [
        5060
        5061
      ];
      allowedUDPPortRanges = [
        {
          from = 10000;
          to = 20000;
        }
        {
          # Keep this in sync with config/rtp.conf.
          from = 52000;
          to = 52200;
        }
      ];
    };

    services.asterisk = enabled // {
      package = pkgs.asterisk;
      useTheseDefaultConfFiles = [ ];
      confFiles = mapAttrs (_: file: builtins.readFile file) {
        "modules.conf" = ./config/modules.conf;
        "http.conf" = ./config/http.conf;
        "rtp.conf" = ./config/rtp.conf;
      };
    };
  };
}
