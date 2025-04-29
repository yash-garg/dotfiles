{ caddy, ... }:
caddy.withPlugins {
  plugins = [
    "github.com/tailscale/caddy-tailscale@v0.0.0-20250207163903-69a970c84556"
  ];
  hash = "sha256-USKNTAvxmuxzhqA8e8XERr1U8513ONG54Md5vcDUERg=";
}
