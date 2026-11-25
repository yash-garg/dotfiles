# Hosts

A list of all hosts currently in use by me.

- `astra`: MacBook Pro 14" with M4 Pro chip & 24GB RAM.
- `aurora`: MacBook Pro 16" with M4 Pro chip & 48GB RAM.
- `orion`: NixOS VM with OrbStack on MacOS.
- `quasar`: NixOS VM with Nvidia GPU on Unraid.
- `vortex`: VM running Minecraft Server and Pl3xMap.
- `zenith`: Oracle Cloud VM running NixOS for development and as a remote builder.

## Rolling out service hardening

1. Verify that `yash` can log in with a key through OpenSSH on Quasar, Vortex, and Zenith and run `sudo -n true`. Deploy-rs connects as this user and activates the system profile as root. Tailscale SSH on these hosts uses the tailnet's SSH policy. Use the OrbStack console for Orion.
2. On the MikroTik, add a read-only SNMP community using `auths.homelab_v2.community` from `secrets/snmp-auth.yaml` (open with SOPS). Restrict it to Quasar's monitoring address. After the Quasar rollout, verify that the Prometheus `mikrotik` target is up, then revoke the old community.
3. Check any manually configured PostgreSQL clients on Zenith and Quasar. A Unix socket requires a matching OS and database role. A client using loopback TCP needs a role with a SCRAM password.
4. Roll out Quasar and Vortex together with Zenith's Gatus update. Gatus checks private applications over Tailscale on TCP 9074. Each probe returns a status and keeps the backend response private. Any same-host media client configured in its UI to reach qBittorrent via a LAN or Tailscale address needs the loopback address instead.
5. On each of the three servers, check `sudo cscli bouncers list` and `sudo cscli metrics` after serving traffic. The firewall bouncer enforces IP decisions at the host and the Caddy bouncer checks visitors at public HTTPS ingress. Quasar's existing direct HTTP origin on public IPv6 TCP 9009 can still bypass Zenith's HTTPS checks.
