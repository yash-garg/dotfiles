{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.hardware.networking;

  # Parse "ip/prefix" into { address, prefixLength }
  parseAddr =
    addr:
    let
      parts = splitString "/" addr;
      ip = head parts;
      prefix =
        if length parts > 1 then
          toInt (elemAt parts 1)
        else if hasInfix ":" ip then
          64
        else
          24;
    in
    {
      address = ip;
      prefixLength = prefix;
    };

  # Parse route string "dest/prefix via gateway" or "dest/prefix"
  parseRoute =
    route:
    let
      parts = splitString " via " route;
      destParts = splitString "/" (head parts);
      dest = head destParts;
      prefix = if length destParts > 1 then toInt (elemAt destParts 1) else 32;
      hasGateway = length parts > 1;
    in
    {
      address = dest;
      prefixLength = prefix;
      via = if hasGateway then elemAt parts 1 else null;
    }
    // optionalAttrs (dest == "0.0.0.0" && hasGateway) { options.onlink = ""; };
in
{
  options.${namespace}.hardware.networking = with types; {
    enable = mkBoolOpt false "Whether to enable networking configuration";

    hostName = mkOpt str "nixos" "The hostname of the machine";
    domain = mkOpt str "" "The domain name of the machine";
    hosts = mkOpt attrs { } "Additional entries for /etc/hosts";

    # Simple interface configuration
    interfaces = mkOpt (attrsOf (submodule {
      options = {
        ipv4 = mkOpt (listOf str) [ ] "IPv4 addresses (e.g., '192.168.1.10/24')";
        ipv6 = mkOpt (listOf str) [ ] "IPv6 addresses (e.g., '2001:db8::1/64')";
        routes = mkOpt (listOf str) [ ] "Routes (e.g., '0.0.0.0/0 via 192.168.1.1')";
        dhcp = mkOpt (nullOr bool) null "Override DHCP for this interface";
      };
    })) { } "Interface configurations";

    # Gateways
    gateway = mkOpt (nullOr str) null "Default IPv4 gateway";
    gateway6 =
      mkOpt (nullOr str) null
        "Default IPv6 gateway (format: 'address' or 'address interface')";

    # Firewall
    ports = mkOpt (listOf port) [ ] "TCP ports to open";
    portsUDP = mkOpt (listOf port) [ ] "UDP ports to open";

    # Feature toggles
    dhcp = mkBoolOpt true "Enable DHCP by default";
    networkManager = mkBoolOpt true "Enable NetworkManager";
  };

  config = mkIf cfg.enable (
    let
      hasStaticIPs = any (iface: iface.ipv4 != [ ] || iface.ipv6 != [ ]) (attrValues cfg.interfaces);
    in
    {
      networking = mkMerge [
        # Base configuration
        {
          inherit (cfg) hostName domain hosts;
          useDHCP = (if hasStaticIPs then mkForce else mkDefault) (cfg.dhcp && !hasStaticIPs);
          networkmanager.enable = cfg.networkManager;
          nftables.enable = true;
          nameservers = [
            "100.100.100.100"
            "1.1.1.1"
            "1.0.0.1"
            "2606:4700:4700::1111"
            "2606:4700:4700::1001"
          ];
          firewall = {
            enable = true;
            allowPing = true;
            allowedTCPPorts = cfg.ports;
            allowedUDPPorts = cfg.portsUDP;
          };
        }

        # Interface configuration
        (mkIf (cfg.interfaces != { }) {
          interfaces = mapAttrs (
            _name: iface:
            let
              hasAddrs = iface.ipv4 != [ ] || iface.ipv6 != [ ];
            in
            {
              useDHCP = if iface.dhcp != null then iface.dhcp else !hasAddrs;
              ipv4 = {
                addresses = map parseAddr iface.ipv4;
              }
              // optionalAttrs (iface.routes != [ ]) {
                routes = map parseRoute iface.routes;
              };
              ipv6.addresses = map parseAddr iface.ipv6;
            }
          ) cfg.interfaces;
        })

        # Gateway configuration
        (mkIf (cfg.gateway != null) { defaultGateway = cfg.gateway; })

        (mkIf (cfg.gateway6 != null) (
          let
            parts = splitString " " cfg.gateway6;
            hasInterface = length parts > 1;
          in
          {
            defaultGateway6 =
              if hasInterface then
                {
                  address = head parts;
                  interface = elemAt parts 1;
                }
              else
                cfg.gateway6;
          }
        ))
      ];
    }
  );
}
