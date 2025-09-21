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
  srv = config.${namespace}.services;
  cfg = srv.nvidia-exporter;
in
{
  options.${namespace}.services.nvidia-exporter = {
    enable = mkEnableOption "Enable nvidia-exporter service";
    port = mkOpt types.int ports.exporters.nvidia "Port for the nvidia-exporter server";
  };

  config = mkIf cfg.enable {
    services.prometheus.scrapeConfigs = [
      {
        job_name = "nvidia-exporter";
        static_configs = [ { targets = [ "127.0.0.1:${toString cfg.port}" ]; } ];
      }
    ];

    systemd.services.nvidia-gpu-exporter = {
      description = "NVIDIA GPU Prometheus Exporter";
      after = [ "network.target" ];
      environment.NVIDIA_VISIBLE_DEVICES = "all";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = ''
          ${pkgs.prometheus-nvidia-gpu-exporter}/bin/nvidia_gpu_exporter \
            --web.listen-address=127.0.0.1:${toString cfg.port} \
            --nvidia-smi-command /run/current-system/sw/bin/nvidia-smi
        '';
        Restart = "on-failure";
        RestartSec = "5s";
        User = "nvidia-gpu-exporter";
        Group = "nvidia-gpu-exporter";
        PrivateDevices = false; # Need access to GPU devices
        MemoryMax = "64M";
        CPUQuota = "10%";
      };
    };

    users.groups.nvidia-gpu-exporter = { };
    users.users.nvidia-gpu-exporter = {
      isSystemUser = true;
      group = "nvidia-gpu-exporter";
      description = "NVIDIA GPU Exporter service user";
      extraGroups = [ "video" ]; # Access to GPU devices
    };
  };
}
