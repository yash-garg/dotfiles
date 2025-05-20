{
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
{
  programs.jujutsu = enabled // {
    settings = { };
  };
}
