{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.minecraft-server;
in
{
  options.${namespace}.services.minecraft-server = {
    enable = mkEnableOption "Minecraft Server";

    dataDir =
      mkOpt types.str "${config.users.users.yash.home}/minecraft-data"
        "Minecraft server data directory";
    difficulty = mkOpt types.str "NORMAL" "Minecraft server difficulty";
    memory = mkOpt types.str "16G" "Minecraft server memory";
    motd = mkOpt types.str "§l§cPixel Paradise§r" "Minecraft server MOTD";
    seed = mkOpt types.str "-5584399987456711267" "Minecraft server seed";
    version = mkOpt types.str "1.21.8" "Minecraft server version";
  };

  config = mkIf cfg.enable {
    networking.firewall = {
      allowedTCPPorts = [
        ports.minecraft
        ports.pl3xmap
      ];
      allowedUDPPorts = [ ports.minecraft ];
    };

    sops.secrets.minecraft-env = {
      sopsFile = snowfall.fs.get-file "secrets/minecraft.env";
      format = "dotenv";
    };

    virtualisation.oci-containers.containers.minecraft-server = {
      image = "itzg/minecraft-server:latest";
      environmentFiles = [ config.sops.secrets.minecraft-env.path ];
      environment = {
        SEED = cfg.seed;
        VERSION = cfg.version;
        EULA = "TRUE";
        TYPE = "FABRIC";
        MEMORY = cfg.memory;
        DIFFICULTY = cfg.difficulty;
        # ICON = "/extra/icon.jpeg";
        OVERRIDE_ICON = "TRUE";
        MOTD = cfg.motd;
        ENFORCE_WHITELIST = "TRUE";
        EXISTING_WHITELIST_FILE = "SYNCHRONIZE";
        EXISTING_OPS_FILE = "SYNCHRONIZE";
        ONLINE_MODE = "TRUE";
        REMOVE_OLD_MODS = "TRUE";
        MAX_PLAYERS = "2";
        USE_AIKAR_FLAGS = "TRUE";
        VANILLATWEAKS_SHARECODE = "bmipN5,SLs3nU";
        LOG_TIMESTAMP = "TRUE";
        TZ = "Asia/Kolkata";
        MODRINTH_DOWNLOAD_DEPENDENCIES = "required";
        MODRINTH_ALLOWED_VERSION_TYPE = "alpha";
        MODRINTH_PROJECTS = ''
          beautified-chat-server
          c2me-fabric
          chunky
          disconnect-packet-fix
          fabric-api
          ferrite-core
          leaves-us-in-peace
          lithium
          netherportalfix
          no-chat-reports
          pl3xmap
          scaffolding-drops-nearby
          villager-death-messages
        '';
        RCON_CMDS_STARTUP = ''
          /gamerule keepInventory true
          /chunky radius 1000
          /chunky start
        '';
        RCON_CMDS_FIRST_CONNECT = ''
          /chunky pause
        '';
        RCON_CMDS_LAST_DISCONNECT = ''
          /save-all
          /chunky continue
        '';
      };
      ports = [
        "${toString ports.minecraft}:25565"
        "${toString ports.pl3xmap}:8080"
      ];
      log-driver = "journald";
      volumes = [ "${cfg.dataDir}:/data:rw" ];
    };
  };
}
