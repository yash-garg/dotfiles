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
      "ata_piix"
      "uhci_hcd"
      "ahci"
      "sd_mod"
      "sr_mod"
    ];
    kernel.sysctl."net.ipv6.conf.ens19.accept_ra" = 0;
    kernelParams = [
      "console=tty0"
      "console=ttyS0,115200n8"
    ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/64082ecf-f7d4-4396-96b4-285568d46722";
    fsType = "ext4";
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 2048; # in MB (2GB)
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
