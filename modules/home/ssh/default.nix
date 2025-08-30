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
    includes = [ "~/.ssh/work" ];
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        serverAliveInterval = 60;
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
