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
  cfg = config.${namespace}.services.crowdsec;
  caddy = config.${namespace}.services.caddy;
  caddyCredentials = "${config.services.crowdsec.settings.config.config_paths.data_dir}/caddy-bouncer.env";
  bouncer = config.services.crowdsec-firewall-bouncer;
  containerBans =
    family: set:
    mkAfter ''
      chain crowdsec-forward {
        type filter hook forward priority filter; policy accept;
        ct status dnat ${family} saddr @${set} drop
      }
    '';
in
{
  options.${namespace}.services.crowdsec = {
    enable = mkEnableOption "CrowdSec detection and enforcement" // {
      default = config.${namespace}.server.enable && (config.services.openssh.enable || caddy.enable);
    };
    port = mkOpt types.port ports.crowdsec "Loopback Local API port";
  };

  config = mkIf cfg.enable {
    services.crowdsec = {
      enable = true;
      autoUpdateService = true;
      extraGroups = [ "systemd-journal" ] ++ optional caddy.enable config.services.caddy.group;
      readOnlyPaths = optional caddy.enable config.services.caddy.logDir;
      hub = {
        collections = [
          "crowdsecurity/linux"
        ]
        ++ optionals caddy.enable [
          "crowdsecurity/caddy"
          "crowdsecurity/http-cve"
        ];
        # Never turn a missing/invalid visitor header into a ban on a CDN edge.
        postoverflows = optional caddy.enable "crowdsecurity/cdn-whitelist";
      };
      settings = {
        acquisitions =
          optional config.services.openssh.enable {
            source = "journalctl";
            journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
            labels.type = "syslog";
          }
          ++ optional caddy.enable {
            source = "file";
            filenames = [ "${config.services.caddy.logDir}/access.log" ];
            # Caddy creates the log after CrowdSec has started on first boot.
            force_inotify = true;
            labels.type = "caddy";
          };
        config = {
          api.server.listen_uri = "127.0.0.1:${toString cfg.port}";
          prometheus = {
            enabled = true;
            listen_addr = "127.0.0.1";
            listen_port = ports.exporters.crowdsec;
          };
        };
      };
    };

    # The native module creates its own API key at runtime and manages IPv4/IPv6 rules.
    services.crowdsec-firewall-bouncer.enable = config.services.openssh.enable;

    # Published container ports can use DNAT and pass through FORWARD instead of INPUT.
    networking.nftables.tables =
      let
        inherit (bouncer.settings.nftables) ipv4 ipv6;
      in
      mkIf
        (
          bouncer.enable
          && bouncer.createRulesets
          && bouncer.settings.mode == "nftables"
          && any (container: container.ports != [ ]) (
            attrValues config.virtualisation.oci-containers.containers
          )
        )
        {
          ${ipv4.table}.content = mkIf (ipv4.enabled && ipv4.set-only) (
            containerBans "ip" "crowdsec-blacklists"
          );
          ${ipv6.table}.content = mkIf (ipv6.enabled && ipv6.set-only) (
            containerBans "ip6" "crowdsec6-blacklists"
          );
        };

    services.prometheus.scrapeConfigs = [
      {
        job_name = "crowdsec";
        static_configs = [ { targets = [ "127.0.0.1:${toString ports.exporters.crowdsec}" ]; } ];
      }
    ];

    # Caddy needs request-layer enforcement: a firewall sees Cloudflare's IP, not the visitor.
    # Register a distinct bouncer key locally. Only root/systemd reads the environment file;
    # neither the generated key nor an interpolated Caddy configuration enters the Nix store.
    systemd.services.crowdsec-caddy-register = mkIf caddy.enable {
      description = "Register the Caddy CrowdSec bouncer";
      requires = [ "crowdsec.service" ];
      after = [ "crowdsec.service" ];
      before = [ "caddy.service" ];
      path = [
        config.services.crowdsec.package
        pkgs.jq
        pkgs.coreutils
      ];
      script = ''
        set -eu
        umask 077
        if cscli bouncers list --output json | jq -e 'any(.[]; .name == "caddy")' >/dev/null; then
          if [ -s ${caddyCredentials} ]; then
            exit 0
          fi
          cscli bouncers delete caddy
        fi
        key=$(cscli bouncers add caddy --output raw)
        printf 'CROWDSEC_API_KEY=%s\n' "$key" > ${caddyCredentials}.tmp
        mv ${caddyCredentials}.tmp ${caddyCredentials}
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = config.services.crowdsec.user;
        Group = config.services.crowdsec.group;
        UMask = "0077";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ReadWritePaths = [ "/var/lib/crowdsec" ];
      };
    };

    # Create the log directory before CrowdSec starts (Caddy itself starts later).
    systemd.tmpfiles.rules = optional caddy.enable "d ${config.services.caddy.logDir} 0750 ${config.services.caddy.user} ${config.services.caddy.group} -";

    systemd.services.caddy = mkIf caddy.enable {
      requires = [ "crowdsec-caddy-register.service" ];
      after = [ "crowdsec-caddy-register.service" ];
      serviceConfig = {
        EnvironmentFile = [ caddyCredentials ];
        LogsDirectoryMode = "0750";
      };
    };
  };
}
