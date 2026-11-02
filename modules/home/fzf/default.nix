{ lib, namespace, ... }:
with lib.${namespace};
{
  imports = [ ./colors.nix ];

  programs.fzf = enabled // {
    defaultCommand = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git --no-ignore";
  };
}
