{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.ollama;
in
{
  options.${namespace}.services.ollama = {
    enable = mkEnableOption "Ollama AI";
  };

  config = mkIf cfg.enable {
    services.ollama = enabled // {
      loadModels = [ "dolphin-mistral" ];
      openFirewall = true;
      port = ports.ollama;
    };
  };
}
