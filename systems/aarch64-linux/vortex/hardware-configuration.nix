{

  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "virtio_scsi"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  hardware.facter = {
    reportPath = ./facter.json;
    detected.graphics.enable = false;
  };

  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s6.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
