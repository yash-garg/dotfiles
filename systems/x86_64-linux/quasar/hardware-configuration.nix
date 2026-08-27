{
  config,
  lib,
  modulesPath,
  ...
}:
let
  driverPkg = config.boot.kernelPackages.nvidiaPackages.stable;
  unraid = "10.0.20.244";
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "ehci_pci"
    "sr_mod"
    "uhci_hcd"
    "virtio_balloon"
    "virtio_blk"
    "virtio_pci"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems =
    let
      defaultOpts = {
        fsType = "nfs";
        options = [
          "rw"
          "hard"
          "intr"
          "vers=4"
          "proto=tcp"
        ];
      };
      mounts = {
        "/mnt/backups" = "/mnt/user/backups";
        "/mnt/books" = "/mnt/user/data/media/books";
        "/mnt/documents" = "/mnt/user/documents";
        "/mnt/downloads" = "/mnt/user/downloads";
        "/mnt/media/main/movies" = "/mnt/user/data/media/movies";
        "/mnt/media/main/tv" = "/mnt/user/data/media/tv";
        "/mnt/media/samsung" = "/mnt/disks/Samsung_External";
        "/mnt/photos" = "/mnt/user/data/media/photos";
      };
    in
    lib.mapAttrs (
      _mountPoint: remotePath:
      defaultOpts
      // {
        device = "${unraid}:${remotePath}";
      }
    ) mounts;

  hardware = {
    facter = {
      reportPath = ./facter.json;
      detected.graphics.enable = false;
    };
    graphics = {
      enable = true;
      package = driverPkg;
    };
    nvidia = {
      nvidiaPersistenced = true;
      nvidiaSettings = false;
      open = true;
      package = driverPkg;
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
