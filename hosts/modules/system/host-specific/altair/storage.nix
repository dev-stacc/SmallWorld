{ ... } : {
    fileSystems."/mnt/models" = {
        device = "/dev/disk/by-id/ata-Lexar_SSD_J33156J015759-part1";
        fsType = "ext4";
        options = [
            "defaults"
            "nofail"
            "noatime"
        ];
    };
}
