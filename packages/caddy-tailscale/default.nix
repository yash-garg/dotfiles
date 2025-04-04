{ caddy, ... }:
caddy.withPlugins {
  plugins = [
    "github.com/tailscale/caddy-tailscale@v0.0.0-20250207163903-69a970c84556"
  ];
  hash = "sha256-UR9CG/zIslkXHDj1fDWmhx8hJZ8VLvZzOTGvGqqx1Ls=";
}
