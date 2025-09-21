{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.adguard;
  mkFilter = name: {
    enabled = true;
    url = "https://adguardteam.github.io/HostlistsRegistry/assets/${name}";
  };
in
{
  options.${namespace}.services.adguard = {
    enable = mkEnableOption "Adguard Home Server";
    host = mkOpt types.str "0.0.0.0" "IP to listen on";
    port = mkOpt types.int ports.adguard "Port to listen on";
  };

  config = mkIf cfg.enable {
    networking = {
      firewall = {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
      };
      interfaces.ens12 = {
        useDHCP = true;
        ipv4.addresses = mkIf (cfg.host != "0.0.0.0") [
          {
            address = cfg.host;
            prefixLength = 24;
          }
        ];
      };
    };

    services.adguardhome = enabled // {
      inherit (cfg) port host;
      openFirewall = true;
      settings = {
        dns = {
          bind_hosts = [ cfg.host ];
          enable_dnssec = true;
          bootstrap_dns = [
            "1.1.1.1"
            "1.0.0.1"
            "2606:4700:4700::1111"
            "2606:4700:4700::1001"
          ];
          fallback_dns = [
            "8.8.8.8"
            "8.8.4.4"
          ];
          upstream_dns = [
            "1.1.1.1"
            "1.0.0.1"
            "[/ts.net/]100.100.100.100"
          ];
        };
        filtering = {
          blocking_mode = "nxdomain";
          filtering_enabled = true;
          parental_enabled = false;
          protection_enabled = true;
          safe_search.enabled = false;
          rewrites = [
            {
              domain = "*.orb.lab";
              answer = "10.0.0.3";
            }
          ];
        };
        filters = map mkFilter [
          "filter_1.txt" # AdGuard DNS filter
          "filter_2.txt" # AdAway Default Blocklist
          "filter_3.txt" # Peter Lowe's Blocklist
          "filter_27.txt" # OISD Blocklist Big
          "filter_33.txt" # Steven Black's List
          "filter_59.txt" # AdGuard DNS Popup Hosts filter
        ];
        http.address = "0.0.0.0:${toString cfg.port}";
        user_rules = [
          "@@||t.co^"
          "@@||www.t.co^"
        ];
      };
    };
  };
}
