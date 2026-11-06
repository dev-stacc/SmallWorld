{ ... } : {
    biggerworld.ups = {
        role = "slave";
        master = "aperture";
    };

    boot.loader.grub = {
        enable = true;
        device = "/dev/disk/by-id/ata-Hitachi_HTS545050B9A300_101102PBN40317FU36EE";
    };

    # Broken eDP panel; force HDMI as the only display the kernel sees.
    # No-op once the panel is physically stripped.
    boot.kernelParams = [
        "video=eDP-1:d"
        "video=LVDS-1:d"
    ];

    swapDevices = [{
        device = "/swapfile";
        size = 8192;
    }];
}
