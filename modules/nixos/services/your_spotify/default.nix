{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.your-spotify;
in
{
  options.${namespace}.services.your-spotify = {
    enable = mkEnableOption { description = "Enable the Your Spotify service"; };

    domain = mkOption {
      type = types.str;
      default = "turtle-lake.ts.net";
      description = "The domain on which the Your Spotify service will be hosted";
    };

    clientID = mkOption {
      type = types.str;
      default = "";
      description = "The client ID for the Spotify API";
    };

    port = mkOption {
      type = types.int;
      default = 9001;
      description = "The port on which the Your Spotify service will listen";
    };

    secretFile = mkOption {
      type = types.path;
      description = "The path to the file containing the Spotify API secret";
    };
  };

  config = mkIf cfg.enable {
    services.your_spotify = enabled // {
      enableLocalDB = true;
      settings = {
        PORT = cfg.port;
        SPOTIFY_PUBLIC = cfg.clientID;
        CLIENT_ENDPOINT = "https://spotify.${cfg.domain}";
        API_ENDPOINT = "https://spotify.${cfg.domain}/api";
      };
      spotifySecretFile = cfg.secretFile;
    };
  };
}
