{
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  settings = builtins.readFile ./config.toml;
in
{
  programs.jujutsu = enabled // {
    settings = builtins.fromTOML settings;
  };
}
