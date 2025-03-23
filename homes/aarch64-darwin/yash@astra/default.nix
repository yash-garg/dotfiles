{ namespace, ... }:
{
  imports = [ ../common.nix ];

  profiles.${namespace} = {
    git.userEmail = "y.garg.extern@famedly.com";
  };
}
