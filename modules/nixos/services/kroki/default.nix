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
  cfg = config.${namespace}.services.kroki;
  networkName = "kroki-net";
in
{
  options.${namespace}.services.kroki = {
    enable = mkEnableOption "Kroki: Diagram as a Code";
    domain = mkOpt types.str "ipx.ovh" "The domain name for the Kroki service";
    port = mkOpt types.int ports.kroki.core "The port for the Kroki gateway";
  };

  config = mkIf cfg.enable {
    # Create a dedicated Docker network so containers can resolve each other by name
    systemd.services.docker-kroki-network = {
      description = "Create Docker network for Kroki containers";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      before = [
        "docker-kroki.service"
        "docker-kroki-mermaid.service"
        "docker-kroki-excalidraw.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${pkgs.docker}/bin/docker network rm ${networkName} || true";
      };
      script = ''
        ${pkgs.docker}/bin/docker network inspect ${networkName} >/dev/null 2>&1 \
          || ${pkgs.docker}/bin/docker network create ${networkName}
      '';
    };

    # Ensure all kroki containers start after the network is ready
    systemd.services = {
      docker-kroki.after = [ "docker-kroki-network.service" ];
      docker-kroki.requires = [ "docker-kroki-network.service" ];
      docker-kroki-mermaid.after = [ "docker-kroki-network.service" ];
      docker-kroki-mermaid.requires = [ "docker-kroki-network.service" ];
      docker-kroki-excalidraw.after = [ "docker-kroki-network.service" ];
      docker-kroki-excalidraw.requires = [ "docker-kroki-network.service" ];
    };

    virtualisation.oci-containers.containers = {
      kroki = {
        image = "yuzutech/kroki";
        autoStart = true;
        ports = [ "${toString cfg.port}:8000" ];
        environment = {
          KROKI_MERMAID_HOST = "kroki-mermaid";
          KROKI_EXCALIDRAW_HOST = "kroki-excalidraw";
        };
        dependsOn = [
          "kroki-mermaid"
          "kroki-excalidraw"
        ];
        extraOptions = [ "--network=${networkName}" ];
      };

      kroki-mermaid = {
        image = "yuzutech/kroki-mermaid";
        autoStart = true;
        extraOptions = [ "--network=${networkName}" ];
      };

      kroki-excalidraw = {
        image = "yuzutech/kroki-excalidraw";
        autoStart = true;
        extraOptions = [ "--network=${networkName}" ];
      };
    };

    dots.services.caddy.services.kroki = {
      inherit (cfg) domain;
      upstream = "localhost:${toString cfg.port}";
    };
  };
}
