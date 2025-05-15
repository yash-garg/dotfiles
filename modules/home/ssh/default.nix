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
    includes = [ "~/.ssh/work" ];
    matchBlocks = {
      "*" = {
        sendEnv = [ "COLORTERM" ];
        setEnv = {
          TERM = "xterm-256color";
        };
        extraOptions = mkIf pkgs.stdenv.isDarwin {
          IgnoreUnknown = "UseKeychain";
          UseKeychain = "yes";
        };
      };
      "github.com".identityFile = "~/.ssh/git-ssh";
    };
  };
}
