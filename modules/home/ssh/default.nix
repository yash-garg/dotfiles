{
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
{
  config = {
    programs.ssh = enabled // {
      addKeysToAgent = "yes";
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
          extraOptions = {
            IgnoreUnknown = "UseKeychain";
            UseKeyChain = "yes";
          };
        };
      };
    };
  };
}
