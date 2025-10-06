{
  config,
  lib,
  modulesPath,
  ...
}:
let
  driverPkg = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "580.82.09";
    sha256_64bit = "sha256-Puz4MtouFeDgmsNMKdLHoDgDGC+QRXh6NVysvltWlbc=";
    sha256_aarch64 = "sha256-6tHiAci9iDTKqKrDIjObeFdtrlEwjxOHJpHfX4GMEGQ=";
    openSha256 = "sha256-YB+mQD+oEDIIDa+e8KX1/qOlQvZMNKFrI5z3CoVKUjs=";
    settingsSha256 = "sha256-um53cr2Xo90VhZM1bM2CH4q9b/1W2YOqUcvXPV6uw2s=";
    persistencedSha256 = "sha256-lbYSa97aZ+k0CISoSxOMLyyMX//Zg2Raym6BC4COipU=";
  };
  unraid = "10.0.0.253";
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
    in
    {
      "/mnt/documents" = defaultOpts // {
        device = "${unraid}:/mnt/user/documents";
      };
      "/mnt/data" = defaultOpts // {
        device = "${unraid}:/mnt/user/data";
      };
      "/mnt/media/samsung" = defaultOpts // {
        device = "${unraid}:/mnt/disks/Samsung_External";
      };
      "/mnt/media/wd" = defaultOpts // {
        device = "${unraid}:/mnt/disks/WD_External";
      };
    };

  hardware = {
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
