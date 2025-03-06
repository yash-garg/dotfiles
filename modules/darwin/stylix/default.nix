{
  config,
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
{
  stylix = enabled // {
    autoEnable = false;
    base16Scheme = "${inputs.base16-schemes.outPath}/base16/monokai.yaml";
    homeManagerIntegration.followSystem = true;
    image = pkgs.fetchurl {
      url = "https://w.wallhaven.cc/full/l8/wallhaven-l8x38r.jpg";
      sha256 = "sha256-+fAcJv+KssqefsjRToDHybJpk1NG9uf4BRebeHTFq+g=";
    };
  };

  snowfallorg.users.${config.${namespace}.user.name}.home.config = {
    stylix.targets = {
      bat = enabled;
      btop = enabled;
      fzf = enabled;
      yazi = enabled;
      zellij = enabled;
    };
  };
}
