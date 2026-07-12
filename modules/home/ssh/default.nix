{
  lib,
  namespace,
  pkgs,
  ...
}:
with lib;
with lib.${namespace};
{
  programs.ssh = enabled // {
    enableDefaultConfig = false;
    package = pkgs.openssh_hpn;
    includes = [
      "~/.ssh/work"
      "~/.orbstack/ssh/config"
    ];
    settings = {
      "*" =
        {
          AddKeysToAgent = "yes";
          ServerAliveInterval = 60;
          SendEnv = [ "COLORTERM" ];
          SetEnv = {
            TERM = "xterm-256color";
          };
        }
        // optionalAttrs pkgs.stdenv.isDarwin {
          IgnoreUnknown = "UseKeychain";
          UseKeychain = "yes";
        };
      "github.com".IdentityFile = "~/.ssh/git-ssh";
    };
  };
}
