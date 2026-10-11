{ ... } : {
    imports = [ ./monitor.nix ];

    biggerworld.serve = {
        node."/" = "http://127.0.0.1:9847";
        services.home."/" = "http://127.0.0.1:9847";
    };

    boot.loader.grub = {
        enable = true;
        device = "/dev/disk/by-id/ata-ST1000LM024_HN-M101MBB_S314J90F780763";
    };
}
