{ lib, ... } : {
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    fileSystems."/" = {
        device = "/dev/disk/by-label/PLACEHOLDER";
        fsType = "ext4";
    };

    fileSystems."/boot" = {
        device = "/dev/disk/by-label/PLACEHOLDER-ESP";
        fsType = "vfat";
    };
}
