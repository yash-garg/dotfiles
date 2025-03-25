{
  lib,
  namespace,
  ...
}:
with lib.${namespace};
{
  imports = [ ../common.nix ];

  profiles.${namespace} = {
    git.userEmail = "y.garg.extern@famedly.com";
    gpg = enabled;
  };
}
