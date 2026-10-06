# PLACEHOLDER - replace wholesale, on albireo:
#   nixos-generate-config --show-hardware-config > hosts/modules/system/host-specific/albireo/hardware-configuration.nix
{ config, lib, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "ahci" "sd_mod" "usbhid" "ehci_pci" "xhci_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/REPLACE-ME-ROOT";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/REPLACE-ME-BOOT";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  assertions = [{
    assertion = config.fileSystems."/".device != "/dev/disk/by-uuid/REPLACE-ME-ROOT";
    message = ''
      hosts/modules/system/host-specific/albireo/hardware-configuration.nix is still the placeholder.
      On albireo, run:
        nixos-generate-config --show-hardware-config > hosts/modules/system/host-specific/albireo/hardware-configuration.nix
    '';
  }];
}
