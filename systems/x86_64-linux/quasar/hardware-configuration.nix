{
  lib,
  modulesPath,
  ...
}:
let
  unraid = "10.0.0.253";
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "virtio_pci"
    "uhci_hcd"
    "ehci_pci"
    "sr_mod"
    "virtio_blk"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/mnt/documents" = {
    device = "${unraid}:/mnt/user/documents";
    fsType = "nfs";
    options = [
      "rw"
      "hard"
      "intr"
      "vers=4"
      "proto=tcp"
    ];
  };

  fileSystems."/mnt/unraid" = {
    device = "shares";
    fsType = "9p";
    options = [
      "trans=virtio"
      "rw"
      "cache=loose"
    ];
  };

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
