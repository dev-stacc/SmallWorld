{ ... } : {
    boot.initrd.kernelModules = [ "bfq" ];

    services.udev.extraRules = ''
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
    '';
}
