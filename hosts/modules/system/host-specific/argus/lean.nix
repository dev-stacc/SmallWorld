{ lib, ... } : {
    services.journald.extraConfig = ''
        Storage=volatile
        RuntimeMaxUse=16M
        RuntimeMaxFileSize=4M
        ForwardToSyslog=no
        ForwardToWall=no
        Audit=no
    '';

    systemd.coredump.enable = false;

    documentation = {
        enable = false;
        man.enable = false;
        doc.enable = false;
        info.enable = false;
        nixos.enable = false;
    };

    programs = {
        command-not-found.enable = false;
        nano.enable = false;
    };

    fonts.fontconfig.enable = false;

    xdg = {
        mime.enable = false;
        icons.enable = false;
        sounds.enable = false;
    };

    services = {
        udisks2.enable = false;
        logrotate.enable = false;
        lvm.enable = false;
    };

    zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 150;
    };

    boot.kernel.sysctl = {
        "vm.swappiness" = 180;
        "vm.vfs_cache_pressure" = 200;
        "vm.dirty_writeback_centisecs" = 6000;
        "vm.dirty_expire_centisecs" = 6000;
    };

    nix = {
        gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 14d";
        };
        optimise.automatic = true;
        settings = {
            auto-optimise-store = true;
            max-jobs = 1;
            cores = 1;
        };
    };

    environment.defaultPackages = lib.mkForce [ ];
}
