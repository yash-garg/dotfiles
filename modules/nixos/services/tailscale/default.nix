{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.tailscale;
in
{
  options.${namespace}.services.tailscale = {
    enable = mkEnableOption "Tailscale";
    authKeyFile =
      mkOpt (types.nullOr types.path) null
        "Path to a file containing a Tailscale authkey that this device can use to authenticate itself";
    exitNode = mkBoolOpt false "Advertise this device as an exit node";
    # https://tailscale.com/kb/1241/tailscale-up
    extraOptions =
      mkOpt (types.listOf types.str) [ ]
        "List of extra flags passed to the `tailscale` invocation";
    openFirewall = mkBoolOpt true "Open firewall for Tailscale";
    setNameservers = mkBoolOpt true "Set nameservers to Tailscale's DNS servers";
    ssh = mkBoolOpt false "Enable SSH access to this device via Tailscale";
    subnetRouting = {
      enable = mkEnableOption "Enable subnet routing";
      routes = mkOpt (types.listOf types.str) [ ] "List of subnets to advertise to Tailscale";
    };
    tailnet = mkOpt types.str "turtle-lake.ts.net" "Tailscale network name";
  };

  config = mkIf cfg.enable {
    # always allow traffic from Tailscale network
    networking.firewall.trustedInterfaces = mkIf cfg.openFirewall [ "tailscale0" ];
    networking = {
      nameservers = mkIf cfg.setNameservers [
        "100.100.100.100"
        "8.8.8.8"
        "1.1.1.1"
      ];
      search = [ cfg.tailnet ];
    };

    services.tailscale = enabled // {
      inherit (cfg) authKeyFile openFirewall;
      extraUpFlags = concatLists [
        (optional cfg.exitNode "--advertise-exit-node")
        (optionals cfg.ssh [
          "--accept-risk=lose-ssh"
          "--ssh"
        ])
        (optionals cfg.subnetRouting.enable [
          "--advertise-routes=${concatStringsSep "," cfg.subnetRouting.routes}"
        ])
        cfg.extraOptions
      ];
      permitCertUid = "caddy";
      useRoutingFeatures = "both";
    };
  };
}
