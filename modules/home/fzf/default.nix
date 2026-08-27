{ lib, namespace, ... }:
with lib.${namespace};
{
  imports = [ ./colors.nix ];

  programs.fzf = enabled // {
    defaultCommand = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git --no-ignore";
    # Atuin owns Ctrl-R (the interactive history search) in zsh; let fzf's own
    # history widget stand down there instead of fighting over the binding.
    historyWidget.zsh.command = "";
  };
}
