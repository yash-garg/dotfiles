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
  cfg = config.${namespace}.services.jellyfin;
  xmlFormat = pkgs.formats.xml { };
  xmlNamespaces = {
    "@xmlns:xsi" = "http://www.w3.org/2001/XMLSchema-instance";
    "@xmlns:xsd" = "http://www.w3.org/2001/XMLSchema";
  };
  generateXmlConfig = name: content: ''
    ${pkgs.coreutils}/bin/cp --no-preserve=mode,ownership ${xmlFormat.generate "${name}.xml" content} "${config.services.jellyfin.configDir}/${name}.xml"
  '';
in
{
  options.${namespace}.services.jellyfin = {
    enable = mkEnableOption "Jellyfin: Media Server";
    domain = mkOpt types.str "ipx.ovh" "The domain name for jellyfin";
    user = mkOpt types.str "jellyfin" "The user to run jellyfin as";
    group = mkOpt types.str "jellyfin" "The group to run jellyfin as";
  };

  config = mkIf cfg.enable {
    services = {
      jellyfin = enabled // {
        inherit (cfg) user group;
        openFirewall = true;
      };

      prometheus.scrapeConfigs = [
        {
          job_name = "jellyfin";
          static_configs = [ { targets = [ "127.0.0.1:${toString ports.jellyfin}" ]; } ];
        }
      ];
    };

    systemd.services.jellyfin.preStart = ''
      ${generateXmlConfig "branding" {
        BrandingOptions = xmlNamespaces // {
          CustomCss = ''
            @import url("https://cdn.jsdelivr.net/gh/lscambo13/ElegantFin@main/Theme/ElegantFin-jellyfin-theme-build-latest-minified.css");

            .loginDisclaimer {
              width: 100% !important;
            }

            .manualLoginForm,
            .visualLoginForm {
              display: none !important;
            }
          '';
          LoginDisclaimer = ''
            <form action="https://stream.${cfg.domain}/sso/OID/start/authelia">
              <button class="raised button-submit block emby-button">
                Sign in with Authelia
              </button>
            </form>
          '';
          SplashscreenEnabled = false;
        };
      }}

      ${generateXmlConfig "encoding" {
        EncodingOptions = xmlNamespaces // {
          EncodingThreadCount = -1;
          EnableFallbackFont = false;
          EnableAudioVbr = false;
          DownMixAudioBoost = 2;
          DownMixStereoAlgorithm = "None";
          MaxMuxingQueueSize = 2048;
          EnableThrottling = false;
          ThrottleDelaySeconds = 180;
          EnableSegmentDeletion = false;
          SegmentKeepSeconds = 720;
          HardwareAccelerationType = "nvenc";
          VaapiDevice = "/dev/dri/renderD128";
          EncoderPreset = "auto";
          EnableDecodingColorDepth10Hevc = true;
          EnableDecodingColorDepth10Vp9 = true;
          EnableDecodingColorDepth10HevcRext = false;
          EnableDecodingColorDepth12HevcRext = false;
          EnableEnhancedNvdecDecoder = true;
          PreferSystemNativeHwDecoder = true;
          EnableIntelLowPowerH264HwEncoder = false;
          EnableIntelLowPowerHevcHwEncoder = false;
          EnableHardwareEncoding = true;
          AllowHevcEncoding = true;
          AllowAv1Encoding = false;
          EnableSubtitleExtraction = true;
          HardwareDecodingCodecs.string = [
            "vp8"
            "av1"
            "h264"
            "hevc"
            "vp9"
          ];
        };
      }}

      ${generateXmlConfig "system" {
        ServerConfiguration = xmlNamespaces // {
          LogFileRetentionDays = 3;
          IsStartupWizardCompleted = true;
          EnableMetrics = true;
          EnableNormalizedItemByNameIds = true;
          IsPortAuthorized = true;
          QuickConnectAvailable = true;
          EnableCaseSensitiveItemIds = true;
          DisableLiveTvChannelUserDataName = true;
          PreferredMetadataLanguage = "en";
          MetadataCountryCode = "IN";
          ServerName = config.networking.hostName;
          UICulture = "en-US";
          PluginRepositories = {
            RepositoryInfo = [
              {
                Name = "Jellyfin Stable";
                Url = "https://repo.jellyfin.org/files/plugin/manifest.json";
                Enabled = true;
              }
              {
                Name = "Intro Skipper";
                Url = "https://manifest.intro-skipper.org/manifest.json";
                Enabled = true;
              }
              {
                Name = "Jellyfin SSO";
                Url = "https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/manifest-release/manifest.json";
                Enabled = true;
              }
              {
                Name = "Firecore";
                Url = "https://files.firecore.com/jellyfin/manifest.json";
                Enabled = true;
              }
            ];
          };
          TrickplayOptions = {
            EnableHwAcceleration = false;
            EnableHwEncoding = false;
            EnableKeyFrameOnlyExtraction = false;
            ScanBehavior = "NonBlocking";
            ProcessPriority = "BelowNormal";
          };
        };
      }}
    '';
  };
}
