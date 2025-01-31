{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.hardware.audio;
  noise-suppression-for-voice = pkgs.writeTextDir "share/pipewire/pipewire.conf.d/99-noise-cancellation.conf" ''
    context.modules = [
    {   name = libpipewire-module-filter-chain
        args = {
            node.description =  "Noise Canceling source"
            media.name =  "Noise Canceling source"
            filter.graph = {
                nodes = [
                    {
                        type = ladspa
                        name = rnnoise
                        plugin = ${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so
                        label = noise_suppressor_mono
                        control = {
                            "VAD Threshold (%)" = 50.0
                        }
                    }
                ]
            }
            capture.props = {
                node.name =  "effect_input.rnnoise"
                node.passive = true
                audio.rate = 48000
            }
            playback.props = {
                node.name =  "effect_output.rnnoise"
                media.class = Audio/Source
                audio.rate = 48000
            }
        }
    }
    ]
  '';
in
{
  options.${namespace}.hardware.audio = {
    enable = mkEnableOption "Profile for audio hardware";
    noise-cancellation = mkBoolOpt true "Enable noise cancellation for voice";
  };

  config = mkIf cfg.enable {
    security.rtkit = enabled;

    services.pulseaudio = disabled;
    services.pipewire = enabled // {
      alsa = enabled // {
        support32Bit = true;
      };
      configPackages = mkIf cfg.noise-cancellation [ noise-suppression-for-voice ];
      pulse = enabled;
    };
  };
}
