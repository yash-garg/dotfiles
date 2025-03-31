{
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
    base16Scheme = "${inputs.base16-schemes.outPath}/base16/catppuccin-mocha.yaml";
    homeManagerIntegration.followSystem = true;
    image = pkgs.fetchurl {
      url = "https://w.wallhaven.cc/full/l8/wallhaven-l8x38r.jpg";
      sha256 = "sha256-+fAcJv+KssqefsjRToDHybJpk1NG9uf4BRebeHTFq+g=";
    };
  };
}
