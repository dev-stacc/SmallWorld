{ ... } : {
    boot.loader.grub = {
        enable = true;
        device = "/dev/disk/by-label/NIXBOOT";
    };
}
