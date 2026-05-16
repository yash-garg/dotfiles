{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
let
  cfg = config.profiles.${namespace}.neovim;
in
{
  options.profiles.${namespace}.neovim = {
    enable = mkEnableOption "Enable neovim profile";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      neovim

      # LSP servers (expected on PATH by nvim-lspconfig)
      nixd
      biome
      gopls
      golangci-lint-langserver
      rust-analyzer
      ccls
      cmake-language-server
      vscode-langservers-extracted # html / css / json / eslint
      typescript-language-server
      tailwindcss-language-server
      dart
      kotlin-language-server
      sqls
      ruff
      docker-compose-language-service
      yaml-language-server

      # Formatters
      stylua
      nixfmt
    ];

    xdg.configFile."nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/modules/home/neovim/config";

    programs.tmux.plugins = [ pkgs.tmuxPlugins.vim-tmux-navigator ];
  };
}
