{
  lib,
  namespace,
  pkgs,
  ...
}:
with lib;
with lib.${namespace};
{
  programs.gh = enabled // {
    settings = {
      version = 1;
      git_protocol = "https";
      prompt = "enabled";
    };
  };
}
