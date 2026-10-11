{
  lib,
  writeShellApplication,
  neovim,
  nixd,
  biome,
  gopls,
  golangci-lint-langserver,
  typescript-language-server,
  tailwindcss-language-server,
  dart,
  ruff,
  docker-compose-language-service,
  yaml-language-server,
  stylua,
  nixfmt,
}:
let
  configSrc = lib.cleanSource ../../modules/home/neovim/config;
in
writeShellApplication {
  name = "nvim";
  runtimeInputs = [
    neovim
    nixd
    biome
    gopls
    golangci-lint-langserver
    typescript-language-server
    tailwindcss-language-server
    dart
    ruff
    docker-compose-language-service
    yaml-language-server
    stylua
    nixfmt
  ];
  text = ''
    config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/dots-nvim"
    mkdir -p "$config_dir"
    cp -rf "${configSrc}/." "$config_dir/"
    chmod -R u+w "$config_dir"
    NVIM_APPNAME=dots-nvim exec nvim "$@"
  '';
}
