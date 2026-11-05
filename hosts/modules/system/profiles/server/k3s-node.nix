{ ... } : {
    services.k3s.gracefulNodeShutdown = {
        enable = true;
        shutdownGracePeriod = "45s";
        shutdownGracePeriodCriticalPods = "15s";
    };

    systemd.settings.Manager.InhibitDelayMaxSec = 60;
}
