{ config, ... } : {
    fileSystems."/mnt/storage" = {
        device = "dev/disk/by-uuid/98455c04-f815-4795-aef8-d6f1deefd49e";
        fsType = "ext4";
        options = [
            "defaults"
            "nofail"
        ];
    };
}
