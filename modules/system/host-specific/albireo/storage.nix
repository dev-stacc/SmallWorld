# zpool create -o ashift=12 -O compression=lz4 -O atime=off -O xattr=sa \
#   -O acltype=posixacl -O mountpoint=none bigstorage /dev/disk/by-id/...
# zfs create -o mountpoint=/srv/media-backup bigstorage/media-backup
# zfs create -o mountpoint=/srv/nextcloud    bigstorage/nextcloud
# zfs create -o mountpoint=/srv/important    bigstorage/important
# zfs create -o mountpoint=/srv/nfs          bigstorage/nfs
# zfs create -o mountpoint=/srv/backup       smallstorage/backup
{ ... } : {
    boot = {
        supportedFilesystems = [ "zfs" ];
        zfs.extraPools = [ "bigstorage" "smallstorage" ];

        # default is true until 26.11; forcing an unclean pool risks data loss
        zfs.forceImportRoot = false;
        kernelParams = [ "zfs.zfs_arc_max=4294967296" ];  # FIXME: size against `free -g`
    };

    services.zfs.autoScrub.enable = true;

    # uids are fixed by the upstream images: 33 www-data, 999 postgres
    systemd.tmpfiles.rules = [
        "d /srv/nextcloud       0755 root root -"
        "d /srv/nextcloud/html  0750 33   33   -"
        "d /srv/nextcloud/db    0700 999  999  -"
        "d /srv/nextcloud/dumps 0750 999  999  -"
    ];
}
