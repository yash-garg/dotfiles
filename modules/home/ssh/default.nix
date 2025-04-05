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
    addKeysToAgent = "yes";
    package = pkgs.openssh_hpn;
    serverAliveInterval = 60;
    matchBlocks = {
      "*" = {
        sendEnv = [ "COLORTERM" ];
        setEnv = {
          TERM = "xterm-256color";
        };
      };
      "github.com" = {
        identityFile = "~/.ssh/git-ssh";
        extraOptions = mkIf pkgs.stdenv.isDarwin {
          IgnoreUnknown = "UseKeychain";
          UseKeyChain = "yes";
        };
      };
    };
  };
}
