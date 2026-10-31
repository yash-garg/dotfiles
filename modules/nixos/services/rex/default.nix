{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.rex;
in
{
  options.${namespace}.services.rex = {
    enable = mkEnableOption "Rex shared server";
    socketActivation = mkBoolOpt false "Start on first client connection instead of at boot";
    socketPath =
      mkOpt (types.nullOr types.str) null
        "Unix socket path; required when socketActivation is true";
    extraUsers = mkOpt (types.listOf types.str) [ ] "Users to add to the rex group";
    loginServer = {
      enable = mkEnableOption "Rex login server (per-account)";
      socketActivation = mkBoolOpt false "Start login server on first client connection";
      accounts = mkOpt (types.attrsOf (
        types.submodule {
          options.principals =
            mkOpt (types.listOf types.str) [ ]
              "Principals allowed to log in (e.g. \"tailscale:user@github\")";
        }
      )) { } "Accounts written to /etc/rex/accounts.jsonc; system users must exist separately";
      tailscaleServe.enable = mkEnableOption "Expose via Tailscale Serve; requires HTTPS enabled on the tailnet";
    };
  };

  config =
    let
      sharedEnabled = cfg.enable;
      loginEnabled = cfg.loginServer.enable;
    in
    {
      assertions = [
        {
          assertion = !(sharedEnabled && loginEnabled);
          message = "${namespace}.services.rex: shared server and login server are mutually exclusive";
        }
        {
          assertion = !(sharedEnabled && cfg.socketActivation && cfg.socketPath == null);
          message = "${namespace}.services.rex: socketActivation requires socketPath";
        }
        {
          assertion = !(cfg.loginServer.tailscaleServe.enable && !loginEnabled);
          message = "${namespace}.services.rex: tailscaleServe requires loginServer.enable";
        }
      ];

      services.rex = mkMerge [
        (mkIf sharedEnabled (
          {
            enable = true;
          }
          // optionalAttrs cfg.socketActivation {
            socketActivation = true;
            inherit (cfg) socketPath;
          }
        ))
        (mkIf loginEnabled {
          loginServer = {
            enable = true;
            inherit (cfg.loginServer) accounts;
          }
          // optionalAttrs cfg.loginServer.socketActivation { socketActivation = true; }
          // optionalAttrs cfg.loginServer.tailscaleServe.enable { tailscaleServe.enable = true; };
        })
      ];

      users.groups.rex.members = mkIf sharedEnabled cfg.extraUsers;
    };
}
