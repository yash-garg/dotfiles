{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.bird;

  bgpPeerType = types.submodule {
    options = {
      name = mkOpt types.str "peer1" "Name of the BGP peer";
      localAs = mkOpt types.int 64512 "Local Autonomous System Number";
      remoteAs = mkOpt types.int 64513 "Remote Autonomous System Number";
      neighborAddress = mkOpt types.str "2001:db8::1" "Neighbor IP address (IPv4 or IPv6)";
      sourceAddress = mkOpt (types.nullOr types.str) null "Source address for BGP connection";
      multihop = mkOpt (types.nullOr types.int) null "Enable multihop BGP with specified TTL";
      import = mkOpt types.str "none" "Import filter (none, all, or filter name)";
      export = mkOpt types.str "none" "Export filter (none, all, or filter name)";
      gracefulRestart = mkBoolOpt false "Enable graceful restart";
      password = mkOpt (types.nullOr types.str) null "Password for BGP connection";
      extraConfig = mkOpt types.lines "" "Additional BGP peer configuration";
    };
  };

  staticRouteType = types.submodule {
    options = {
      prefix = mkOpt types.str "2001:db8:1000::/48" "Route prefix";
      via =
        mkOpt (types.nullOr types.str) null
          "Gateway address (optional, not used with blackhole/unreachable/reject)";
      type = mkOpt (types.nullOr (
        types.enum [
          "blackhole"
          "unreachable"
          "reject"
        ]
      )) null "Special route type (blackhole, unreachable, or reject)";
    };
  };
in
{
  options.${namespace}.services.bird = {
    enable = mkEnableOption "Bird: Internet Routing Daemon";
    routerId = mkOpt types.str "192.0.2.1" "Router ID for Bird (typically your main IPv4 address)";
    bgpPeers = mkOpt (types.listOf bgpPeerType) [ ] "BGP peer configurations";
    staticRoutes = mkOpt (types.listOf staticRouteType) [ ] "Static routes to configure";
    kernelScanTime = mkOpt types.int 60 "Kernel protocol scan time in seconds";
    deviceScanTime = mkOpt types.int 60 "Device protocol scan time in seconds";
    extraConfig = mkOpt types.lines "" "Additional Bird configuration";
  };

  config = mkIf cfg.enable {
    services.bird = enabled // {
      autoReload = true;
      checkConfig = false; # Can't check config with runtime secrets
      config = ''
        log syslog all;

        router id ${cfg.routerId};

        protocol kernel {
          scan time ${toString cfg.kernelScanTime};
          ipv6 {
            import none;
            export none;
          };
        }

        protocol device {
          scan time ${toString cfg.deviceScanTime};
        }

        ${optionalString (cfg.bgpPeers != [ ]) (
          concatMapStringsSep "\n\n" (peer: ''
            protocol bgp ${peer.name} {
              local as ${toString peer.localAs};
              ${optionalString (peer.sourceAddress != null) "source address ${peer.sourceAddress};"}
              ipv6 {
                import ${peer.import};
                export ${peer.export};
              };
              ${optionalString peer.gracefulRestart "graceful restart on;"}
              ${optionalString (peer.multihop != null) "multihop ${toString peer.multihop};"}
              neighbor ${peer.neighborAddress} as ${toString peer.remoteAs};
              ${optionalString (peer.password != null) "password \"${peer.password}\";"}
              ${peer.extraConfig}
            }
          '') cfg.bgpPeers
        )}

        ${optionalString (cfg.staticRoutes != [ ]) ''
          protocol static {
            ipv6;
            ${concatMapStringsSep "\n    " (
              route:
              if route.type != null then
                "route ${route.prefix} ${route.type};"
              else if route.via != null then
                "route ${route.prefix} via ${route.via};"
              else
                throw "Static route ${route.prefix} must have either 'via' or 'type' specified"
            ) cfg.staticRoutes}
          }
        ''}

        ${cfg.extraConfig}
      '';
    };
  };
}
