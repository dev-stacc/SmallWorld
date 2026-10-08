{ lib, ... } : {
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    fileSystems."/" = {
        device = "/dev/disk/by-label/PLACEHOLDER";
        fsType = "ext4";
    };
}
