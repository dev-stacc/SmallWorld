{ ... } : {
    imports = [ ./monitor.nix ];

    boot.loader.grub = {
        enable = true;
        device = "/dev/disk/by-id/ata-ST1000LM024_HN-M101MBB_S314J90F780763";
    };
}
