{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.server;
in
{
  options.${namespace}.server = {
    enable = mkEnableOption "Profile for servers";

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Extra packages to install on servers";
    };
  };

  config = mkIf cfg.enable {
    dots.virtualisation = enabled;

    users.users.yash.packages = with pkgs; [
      nh
    ];
  };
}
