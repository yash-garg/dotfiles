{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.backend-health;
  routes = concatStringsSep "\n" (
    mapAttrsToList (name: endpoint: ''
      @${name} {
        method GET
        expression {http.request.uri} == "/${name}"
      }
      handle @${name} {
        reverse_proxy 127.0.0.1:${toString endpoint.port} {
          method GET
          rewrite ${endpoint.path}
          header_up -*
          header_up Host localhost
          transport http {
            dial_timeout 2s
            response_header_timeout 2s
          }
          @healthy status ${concatMapStringsSep " " toString endpoint.statuses}
          handle_response @healthy {
            respond 200
          }
          handle_response {
            respond 503
          }
        }
      }
    '') cfg.endpoints
  );
in
{
  options.${namespace}.services.backend-health = {
    enable = mkEnableOption "Tailscale status-only backend checks";
    port = mkOpt types.port ports.backend-health "Port for the Tailscale status-only listener";
    endpoints = mkOpt (types.attrsOf (
      types.submodule {
        options = {
          port = mkOption { type = types.port; };
          path = mkOpt types.str "/" "Fixed local HTTP path to check";
          statuses = mkOpt (types.listOf types.int) [ 200 ] "Healthy upstream HTTP statuses";
        };
      }
    )) { } "Local backend checks; only their health is exposed, never backend content";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.${namespace}.services.tailscale.enable && config.services.caddy.enable;
        message = "backend-health requires Tailscale and Caddy";
      }
    ];

    dots.services.tailscale.interfaceOnlyTCPPorts = [ cfg.port ];

    # A separate listener exposes fixed local probes only. No request identity,
    # backend body, redirect, cookie or other upstream header reaches the caller.
    services.caddy.extraConfig = mkAfter ''
      http://:${toString cfg.port} {
        ${routes}
        handle {
          respond 404
        }
        handle_errors {
          respond 503
        }
      }
    '';
  };
}
