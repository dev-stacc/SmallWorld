{ ... } : {
    fileSystems."/mnt/models" = {
        device = "/dev/disk/by-uuid/PLACEHOLDER";
        fsType = "ext4";
        options = [
            "defaults"
            "nofail"
        ];
    };
}
