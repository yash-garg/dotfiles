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
    };

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
