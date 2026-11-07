{ config, ... } : {
    systemd.tmpfiles.rules = [
        "d /var/lib/pihole 0750 root root -"
        "d /var/lib/pihole/etc-pihole 0750 root root -"
        "d /var/lib/pihole/etc-dnsmasq.d 0750 root root -"
    ];

    virtualisation.oci-containers.containers.pihole = {
        image = "docker.io/pihole/pihole:2026.06.0";
        autoStart = true;
        environment = {
            TZ = "America/Toronto";
            FTLCONF_dns_upstreams = "127.0.0.1#5335";
            FTLCONF_dns_listeningMode = "all";
            FTLCONF_dns_port = "53";
            FTLCONF_dns_queryLogging = "false";
            FTLCONF_database_maxDBdays = "0";
            FTLCONF_webserver_port = "8081o";
            FTLCONF_webserver_api_max_sessions = "32";
            FTLCONF_webserver_session_timeout = "900";
            FTLCONF_webserver_session_restore = "false";
        };
        environmentFiles = [
            "${config.biggerworld.provision.dir}/pihole.env"
        ];
        volumes = [
            "/var/lib/pihole/etc-pihole:/etc/pihole"
            "/var/lib/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
        ];
        extraOptions = [ "--network=host" ];
    };

    systemd.services."podman-pihole" = {
        after = [ "unbound.service" "tailscaled.service" ];
        requires = [ "unbound.service" ];
    };

    networking.firewall.interfaces.wlan0 = {
        allowedUDPPorts = [ 53 ];
        allowedTCPPorts = [ 53 ];
    };
}
