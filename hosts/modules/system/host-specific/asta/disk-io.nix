{ ... } : {
    boot.initrd.kernelModules = [ "bfq" ];

    boot.kernel.sysctl = {
        "vm.dirty_bytes" = 268435456;
        "vm.dirty_background_bytes" = 67108864;
    };

    systemd.services.k3s.serviceConfig.IOWeight = 1000;

    services.udev.extraRules = ''
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
    '';
}
