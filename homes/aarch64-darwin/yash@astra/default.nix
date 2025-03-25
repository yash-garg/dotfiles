{
  lib,
  namespace,
  ...
}:
with lib.${namespace};
{
  imports = [ ../common.nix ];

  profiles.${namespace} = {
    gpg = enabled;
  };
}
