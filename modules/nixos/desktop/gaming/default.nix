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
  cfg = config.${namespace}.desktop.gaming;
  quantum = 64;
  rate = 48000;
  qr = "${toString quantum}/${toString rate}";
in
{
  options.${namespace}.desktop.gaming = {
    enable = mkEnableOption "Enable gaming for desktop machines";
  };

  config = mkIf cfg.enable {
    boot.kernel.sysctl = {
      # 20-shed.conf
      "kernel.sched_cfs_bandwidth_slice_us" = 3000;
      # 20-net-timeout.conf
      # This is required due to some games being unable to reuse their TCP ports
      # if they are killed and restarted quickly - the default timeout is too large.
      "net.ipv4.tcp_fin_timeout" = 5;
      # 30-vm.conf
      # USE MAX_INT - MAPCOUNT_ELF_CORE_MARGIN.
      # see comment in include/linux/mm.h in the kernel tree.
      "vm.max_map_count" = 2147483642;
    };

    programs.gamescope = enabled // {
      capSysNice = true;
      args = [
        "--steam"
        "--expose-wayland"
        "--rt"
        "-W 2560"
        "-H 1440"
        "--force-grab-cursor"
        "--grab"
        "--fullscreen"
      ];
    };

    programs.nix-ld = enabled // {
      libraries = pkgs.steam-run.fhsenv.args.multiPkgs pkgs;
    };

    programs.steam = enabled // {
      # Graphical glitches and broken rendering
      gamescopeSession = disabled;
    };

    # Pipewire LowLatency configuration from nix-gaming
    # ref: https://github.com/fufexan/nix-gaming/blob/6caa391790442baea22260296041429fb365e0ce/modules/pipewireLowLatency.nix
    services.pipewire = {
      extraConfig.pipewire = {
        "99-lowlatency" = {
          context = {
            properties.default.clock.min-quantum = quantum;
            modules = [
              {
                name = "libpipewire-module-rtkit";
                flags = [
                  "ifexists"
                  "nofail"
                ];
                args = {
                  nice.level = -15;
                  rt = {
                    prio = 88;
                    time.soft = 200000;
                    time.hard = 200000;
                  };
                };
              }
              {
                name = "libpipewire-module-protocol-pulse";
                args = {
                  server.address = [ "unix:native" ];
                  pulse.min = {
                    req = qr;
                    quantum = qr;
                    frag = qr;
                  };
                };
              }
            ];

            stream.properties = {
              node.latency = qr;
              resample.quality = 1;
            };
          };
        };
      };
    };

    users.users.yash.packages = with pkgs; [
      (prismlauncher.override {
        jdks = [ openjdk21 ];
      })
    ];

    environment.sessionVariables.VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
  };
}
