{
  config,
  lib,
  namespace,
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
        initExtra = "source $HOME/.shell-init";
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
  };
}
