{ config, lib, modulesPath, ... } : {
    imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
    ];

    boot.initrd.availableKernelModules = [
        "ahci"
        "ata_piix"
        "pata_via"
        "ehci_pci"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
    ];

    fileSystems."/" = {
        device = "/dev/disk/by-uuid/2d6556a0-a5d1-4033-8fc0-e4695edf73c7";
        fsType = "ext4";
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    hardware.cpu.intel.updateMicrocode =
        lib.mkDefault config.hardware.enableRedistributableFirmware;
}
