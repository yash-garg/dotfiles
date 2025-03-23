{
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
{
  programs.ssh = enabled // {
    addKeysToAgent = "yes";
    serverAliveInterval = 60;
    matchBlocks = {
      "*" = {
        setEnv = {
          TERM = "xterm-256color";
        };

        sendEnv = [
          "COLORTERM"
        ];
      };
      "github.com" = {
        identityFile = "~/.ssh/git-ssh";
        extraOptions = {
          IgnoreUnknown = "UseKeychain";
          UseKeyChain = "yes";
        };
      };
    };
  };
}
