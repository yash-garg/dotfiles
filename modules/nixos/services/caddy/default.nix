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
  cfg = config.dots.services.caddy;

  cloudflareIPs = [
    "173.245.48.0/20"
    "103.21.244.0/22"
    "103.22.200.0/22"
    "103.31.4.0/22"
    "141.101.64.0/18"
    "108.162.192.0/18"
    "190.93.240.0/20"
    "188.114.96.0/20"
    "197.234.240.0/22"
    "198.41.128.0/17"
    "162.158.0.0/15"
    "104.16.0.0/13"
    "104.24.0.0/14"
    "172.64.0.0/13"
    "131.0.72.0/22"
    "2400:cb00::/32"
    "2606:4700::/32"
    "2803:f800::/32"
    "2405:b500::/32"
    "2405:8100::/32"
    "2a06:98c0::/29"
    "2c0f:f248::/32"
  ];

  allTrustedProxies = trustedProxies.list ++ cloudflareIPs;

  # Common utilities
  normalizeUpstream = u: if hasPrefix "http://" u || hasPrefix "https://" u then u else "http://${u}";

  # Failover options for multiple upstreams
  failoverOpts = ''
    lb_policy first
    fail_duration 30s
    max_fails 2
    unhealthy_latency 5s
    lb_try_duration 15s
    lb_try_interval 500ms
  '';

  # Forward auth snippet
  forwardAuthSnippet =
    let
      authHost = if cfg.auth.url != "" then cfg.auth.url else "localhost:${toString cfg.auth.port}";
    in
    ''
      forward_auth ${authHost} {
        uri /api/authz/forward-auth
        copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
        header_up X-Forwarded-Proto https
      }
    '';

  # Generic service handler - used for all service routing
  # mode: "handle" (inside wildcard block), "site" (standalone), "internal" (HTTP listener)
  mkServiceBlock =
    {
      name,
      svc,
      mode ? "handle",
    }:
    let
      subdomain = if svc.subdomain != null then svc.subdomain else name;
      host = "${subdomain}.${svc.domain}";
      upstream = normalizeUpstream svc.upstream;
      hasMultiple = svc.fallback != null;
      upstreams = if hasMultiple then "${upstream} ${normalizeUpstream svc.fallback}" else upstream;

      # Internal mode uses forwarded headers; others use direct
      headerOpts =
        if mode == "internal" then
          ''
            header_up Host {host}
            header_up X-Real-IP {http.request.header.X-Real-IP}
            header_up X-Forwarded-Proto {http.request.header.X-Forwarded-Proto}
          ''
        else
          ''
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
            ${optionalString hasMultiple failoverOpts}
          '';

      reverseProxyBlock = ''
        reverse_proxy ${upstreams} {
          ${headerOpts}
        }
      '';

      handleContent = ''
        ${optionalString (svc.redirectRoot != null) ''
          @root path /
          redir @root ${svc.redirectRoot} permanent
        ''}
        ${optionalString (cfg.auth.enable && svc.auth) forwardAuthSnippet}
        ${reverseProxyBlock}
      '';
    in
    if mode == "site" then
      ''
        ${host} {
          ${handleContent}
        }
      ''
    else
      ''
        @svc_${name} host ${host}
        handle @svc_${name} {
          ${handleContent}
        }
      '';

  # Server proxy for ingress (Ares -> backends)
  mkServerProxy =
    name: srv:
    let
      hasMultiple = srv.fallback != null;
      upstreams = if hasMultiple then "${srv.address} ${srv.fallback}" else srv.address;
      usesTls = hasInfix ":443" srv.address || hasPrefix "https://" srv.address;
      hosts = concatStringsSep " " srv.hosts;

      tlsOpts = version: ''
        transport http {
          tls
          tls_insecure_skip_verify
          read_timeout 30s
          write_timeout 30s
          versions ${version}
        }
      '';

      commonOpts = ''
        header_up Host {host}
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-Proto {scheme}
        ${optionalString hasMultiple failoverOpts}
      '';
    in
    ''
      @${name} host ${hosts}
      handle @${name} {
        @ws {
          header Connection *Upgrade*
          header Upgrade websocket
        }
        reverse_proxy @ws ${upstreams} {
          ${commonOpts}
          ${optionalString usesTls (tlsOpts "1.1")}
        }
        reverse_proxy ${upstreams} {
          ${commonOpts}
          ${optionalString usesTls (tlsOpts "2")}
        }
      }
    '';

  # Domain handling
  allHosts = flatten (mapAttrsToList (_: srv: srv.hosts) cfg.servers);
  getDomain = host: concatStringsSep "." (tail (splitString "." host));
  serverDomains = unique (map getDomain allHosts);
  serviceDomains = unique (map (svc: svc.domain) (attrValues cfg.services));
  ingressDomains = unique (serverDomains ++ serviceDomains);

  servicesForDomain =
    domain:
    mapAttrsToList (name: svc: { inherit name svc; }) (
      filterAttrs (_: svc: svc.domain == domain) cfg.services
    );

  # Wildcard domain block with all services
  mkDomainBlock =
    domain:
    let
      services = servicesForDomain domain;
      serviceHandles = map (
        { name, svc }:
        mkServiceBlock {
          inherit name svc;
          mode = "handle";
        }
      ) services;
    in
    ''
      *.${domain} {
        ${concatStrings (mapAttrsToList mkServerProxy cfg.servers)}
        ${concatStrings serviceHandles}
        handle {
          respond "Not found" 404
        }
      }
    '';

  # Config blocks
  ingressConfig = optionalString (ingressDomains != [ ]) (
    concatStrings (map mkDomainBlock ingressDomains)
  );

  standaloneConfig = optionalString (cfg.services != { }) (
    concatStrings (
      mapAttrsToList (
        name: svc:
        mkServiceBlock {
          inherit name svc;
          mode = "site";
        }
      ) (filterAttrs (_: svc: !(elem svc.domain ingressDomains)) cfg.services)
    )
  );

  internalListenerConfig = optionalString (cfg.internal.enable && cfg.services != { }) ''
    :${toString cfg.internal.port} {
      ${concatStrings (
        mapAttrsToList (
          name: svc:
          mkServiceBlock {
            inherit name svc;
            mode = "internal";
          }
        ) cfg.services
      )}
      handle {
        respond "Not found" 404
      }
    }
  '';

  # Option types
  serviceSubmodule = types.submodule (_: {
    options = {
      subdomain = mkOpt (types.nullOr types.str) null "Subdomain (defaults to attribute name)";
      domain = mkOpt types.str cfg.domain "Domain for this service";
      upstream = mkOpt types.str "" "Upstream URL";
      fallback = mkOpt (types.nullOr types.str) null "Fallback upstream (for failover)";
      auth = mkBoolOpt true "Require authentication";
      redirectRoot = mkOpt (types.nullOr types.str) null "Redirect / to this path";
    };
  });

  serverSubmodule = types.submodule {
    options = {
      address = mkOpt types.str "" "Primary upstream address";
      fallback = mkOpt (types.nullOr types.str) null "Fallback upstream address";
      hosts = mkOpt (types.listOf types.str) [ ] "Hostnames to route";
    };
  };
in
{
  options.dots.services.caddy = {
    enable = mkEnableOption "Caddy reverse proxy";
    domain = mkOpt types.str "ipx.ovh" "Base domain";

    auth = {
      enable = mkBoolOpt false "Enable forward auth";
      port = mkOpt types.int ports.authelia "Authelia port";
      url = mkOpt types.str "" "Remote auth URL";
    };

    internal = {
      enable = mkBoolOpt false "Enable internal HTTP listener for proxied traffic";
      port = mkOpt types.int ports.caddy "Internal HTTP port";
      trustedProxies = mkOpt (types.listOf types.str) [ ] "Additional trusted proxy IPs";
    };

    servers = mkOpt (types.attrsOf serverSubmodule) { } "Backend servers for ingress";
    services = mkOpt (types.attrsOf serviceSubmodule) { } "Services to proxy";
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      cf-env = {
        sopsFile = snowfall.fs.get-file "secrets/cloudflare.env";
        format = "dotenv";
        owner = config.services.caddy.user;
        inherit (config.services.caddy) group;
      };
      caddy-origin-cert = {
        sopsFile = snowfall.fs.get-file "secrets/cert.pem";
        format = "binary";
        owner = config.services.caddy.user;
        inherit (config.services.caddy) group;
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.internal.enable [ cfg.internal.port ];

    services = {
      caddy = enabled // {
        package = pkgs.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/cloudflare@v0.2.3" ];
          hash = "sha256-bJO2RIa6hYsoVl3y2L86EM34Dfkm2tlcEsXn2+COgzo";
        };
        environmentFile = config.sops.secrets.cf-env.path;
        globalConfig = ''
          acme_dns cloudflare {env.CF_DNS_API_TOKEN}
          email spam@${cfg.domain}
          metrics
          servers {
            trusted_proxies static ${concatStringsSep " " (allTrustedProxies ++ cfg.internal.trustedProxies)}
          }
        '';
        logFormat = ''
          output file /var/log/caddy/caddy_main.log {
            roll_size 100MiB
            roll_keep 5
            roll_keep_for 100d
          }
          format json
          level INFO
        '';
        extraConfig = ingressConfig + standaloneConfig + internalListenerConfig;
      };

      prometheus.scrapeConfigs = [
        {
          job_name = "caddy";
          static_configs = [ { targets = [ "localhost:${toString ports.exporters.caddy}" ]; } ];
        }
      ];
    };
  };
}
