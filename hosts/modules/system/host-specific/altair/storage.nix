{ ... } : {
    fileSystems."/mnt/models" = {
        device = "/dev/disk/by-id/ata-TOSHIBA_MQ01ABD075_626CS42LS-part1";
        fsType = "ext4";
        options = [
            "defaults"
            "nofail"
            "noatime"
        ];
    };
}
