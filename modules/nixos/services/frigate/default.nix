{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.frigate;
  mkCamera =
    { name, path }:
    {
      inherit name;
      value = {
        ffmpeg.inputs = [
          {
            inherit path;
            roles = [ "detect" ];
            hwaccel_args = "preset-nvidia";
          }
        ];
      };
    };
in
{
  options.${namespace}.services.frigate = {
    enable = mkEnableOption "frigate: NVR for IP cameras";
    cameraConfigs = mkOpt (types.listOf types.attrs) [ ] "The camera configurations";
    vaapiDriver = mkOpt types.str "nvidia" "The VAAPI driver to use";
  };

  config = mkIf cfg.enable {
    services.frigate = enabled // {
      inherit (cfg) vaapiDriver;
      hostname = "localhost";
      settings.cameras = builtins.listToAttrs (map mkCamera cfg.cameraConfigs);
    };
  };
}
