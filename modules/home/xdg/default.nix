{
  pkgs,
  lib,
  namespace,
  ...
}:
with lib.${namespace};
{
  xdg = enabled // {
    mime.enable = !pkgs.stdenv.hostPlatform.isDarwin;
  };
}
