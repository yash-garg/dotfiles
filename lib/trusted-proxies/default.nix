{
  # Trusted proxy networks for reverse proxy setups
  # Use these when services need to trust X-Real-IP and X-Forwarded-* headers
  trustedProxies = {
    # List format (for Nix configs)
    list = [
      "127.0.0.1/32"
      "::1/128"
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
      "100.64.0.0/10" # Tailscale/CGNAT
      "fc00::/7" # Unique Local Addresses
      "fd00::/8" # WireGuard internal
      "fe80::/10" # Link-local
      "2a0c:9a40:8911::/48" # Ares IPv6 prefix
      "139.84.177.122/32" # Ares IPv4
    ];

    # Comma-separated format (for env vars like Paperless, Immich, Miniflux)
    commaSeparated = "127.0.0.0/8,::1/128,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,100.64.0.0/10,fc00::/7,fd00::/8,fe80::/10,2a0c:9a40:8911::/48,139.84.177.122/32";

    # Semicolon-separated format (for qBittorrent)
    semicolonSeparated = "127.0.0.0/8;::1/128;10.0.0.0/8;172.16.0.0/12;192.168.0.0/16;100.64.0.0/10;fc00::/7;fd00::/8;fe80::/10;2a0c:9a40:8911::/48;139.84.177.122/32";

    # Space-separated format (for Caddy)
    spaceSeparated = "127.0.0.1/32 ::1/128 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 100.64.0.0/10 fc00::/7 fd00::/8 fe80::/10 2a0c:9a40:8911::/48 139.84.177.122/32";
  };
}
