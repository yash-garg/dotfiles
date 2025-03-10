{ config, ... }:
{
  home = {
    username = config.snowfallorg.user.name;
    homeDirectory = config.snowfallorg.user.home.directory;
  };
}
