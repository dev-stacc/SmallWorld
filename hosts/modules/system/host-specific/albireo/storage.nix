{ username, ... } : {
    systemd.tmpfiles.rules = [
        "d /bigstorage/media-backup    0755 ${username} users -"
        "d /bigstorage/important       0755 ${username} users -"
        "d /bigstorage/nfs             0755 root root -"
        "d /bigstorage/nextcloud       0755 root root -"
        "d /bigstorage/nextcloud/html  0750 33   33   -"
        "d /bigstorage/nextcloud/db    0700 999  999  -"
        "d /bigstorage/nextcloud/dumps 0750 999  999  -"
        "d /smallstorage/backup        0700 root root -"
    ];
}
