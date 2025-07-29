{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.shells.${namespace}.zsh;
  profiles = config.profiles.${namespace};
in
{
  options.shells.${namespace}.zsh = {
    enable = mkEnableOption "Zsh profile";
  };

  config = mkIf cfg.enable {
    programs = {
      zsh = enabled // {
        enableCompletion = true;
        autosuggestion = enabled;
        syntaxHighlighting = enabled;
        history = {
          size = 10000;
          path = "$HOME/.zsh_history";
          ignoreDups = true;
        };
        initContent = ''
          source "${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh"
          source $HOME/.shell-init
        '';
      };

      atuin.enableZshIntegration = true;
      eza.enableZshIntegration = true;
      fzf.enableZshIntegration = true;
      ghostty.enableZshIntegration = profiles.ghostty.enable;
      kitty.shellIntegration.enableZshIntegration = profiles.kitty.enable;
      nix-index.enableZshIntegration = true;
      oh-my-posh.enableZshIntegration = profiles.oh-my-posh.enable;
      starship.enableZshIntegration = profiles.starship.enable;
      wezterm.enableZshIntegration = profiles.wezterm.enable;
      yazi.enableZshIntegration = true;
      zellij.enableZshIntegration = false;
      zoxide.enableZshIntegration = true;
    };

    services.gpg-agent.enableZshIntegration = profiles.gpg.enable;
  };
}
