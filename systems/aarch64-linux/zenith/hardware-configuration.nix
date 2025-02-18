{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot = {
    initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
      "xen_blkfront"
    ];
    initrd.kernelModules = [ "nvme" ];
    loader.grub = {
      configurationLimit = 1;
      efiSupport = true;
      efiInstallAsRemovable = true;
      device = "nodev";
    };
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/B4B3-3A1E";
    fsType = "vfat";
  };

  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
