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

  ipv4AddressType = types.submodule {
    options = {
      address = mkOpt types.str "" "IPv4 address";
      prefixLength = mkOpt types.int 24 "IPv4 prefix length";
    };
  };

  ipv6AddressType = types.submodule {
    options = {
      address = mkOpt types.str "" "IPv6 address";
      prefixLength = mkOpt types.int 64 "IPv6 prefix length";
    };
  };

  interfaceType = types.submodule {
    options = {
      name = mkOpt types.str "eth0" "Interface name";
      ipv4 = mkOpt (types.listOf ipv4AddressType) [ ] "List of IPv4 addresses";
      ipv6 = mkOpt (types.listOf ipv6AddressType) [ ] "List of IPv6 addresses";
      useDHCP = mkBoolOpt true "Whether to use DHCP on this interface";
    };
  };
in
{
  options.${namespace}.hardware.networking = with types; {
    enable = mkBoolOpt false "Whether or not to enable networking support";
    domain = mkOpt str "" "The domain name of the machine";
    hostName = mkOpt str "nixos" "The hostname of the machine";
    hosts = mkOpt attrs { } (mdDoc "An attribute set to merge with `networking.hosts`");
    extra = mkBoolOpt true "Whether or not to enable extra networking features";
    tcpPorts = mkOpt (listOf port) [
      80
      443
      8080
    ] "A list of ports to open in the firewall";

    # Static IP configuration
    interfaces = mkOpt (listOf interfaceType) [ ] "Network interface configurations";
    defaultGateway = mkOpt (nullOr str) null "Default IPv4 gateway";
    defaultGateway6 = mkOpt (nullOr (submodule {
      options = {
        address = mkOpt str "" "IPv6 gateway address";
        interface = mkOpt str "" "Interface for IPv6 gateway";
      };
    })) null "Default IPv6 gateway configuration";
  };

  config = mkIf cfg.enable {
    networking = mkMerge [
      {
        inherit (cfg) domain;
        inherit (cfg) hosts;
        hostName = mkDefault cfg.hostName;

        # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
        # (the default) this is the recommended approach. When using systemd-networkd it's
        # still possible to use this option, but it's recommended to use it in conjunction
        # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
        interfaces.wlan0.useDHCP = mkDefault true;
        useDHCP = mkDefault true;

        # Enable networking
        networkmanager.enable = cfg.extra;
        nftables.enable = cfg.extra;

        firewall = enabled // {
          allowPing = true;
          allowedTCPPorts = cfg.tcpPorts;
        };
      }

      # Static IP configuration
      (mkIf (cfg.interfaces != [ ]) {
        useDHCP = mkForce false;
        interfaces = listToAttrs (
          map (iface: {
            inherit (iface) name;
            value = {
              inherit (iface) useDHCP;
              ipv4.addresses = iface.ipv4;
              ipv6.addresses = iface.ipv6;
            };
          }) cfg.interfaces
        );
      })

      # Default gateways
      (mkIf (cfg.defaultGateway != null) {
        inherit (cfg) defaultGateway;
      })

      (mkIf (cfg.defaultGateway6 != null) {
        defaultGateway6 = {
          inherit (cfg.defaultGateway6) address interface;
        };
      })
    ];
  };
}
