{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.server;
in
{
  options.${namespace}.server = {
    enable = mkEnableOption "Profile for servers";
    extraPackages = mkOpt (types.listOf types.package) [ ] "Extra packages to install on servers";
  };

  config = mkIf cfg.enable {
    boot.kernel.sysctl = {
      "net.ipv6.conf.all.forwarding" = true;
    };

    networking.firewall = {
      allowedUDPPorts = [ ports.wireguard ];
      trustedInterfaces = [ "wg0" ];
    };

    dots = {
      services = {
        chrony = enabled;
      };
    };

    users.users.yash.packages = with pkgs; [
      nfs-utils
      tcpdump
      iperf3
      netcat-gnu
      lsof
      bind.dnsutils
    ];
  };
}
