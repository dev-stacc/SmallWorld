{ config, inputs, ... } : {
    systemd.tmpfiles.rules = [
        "d /var/lib/pihole 0750 root root -"
        "d /var/lib/pihole/etc-pihole 0750 root root -"
        "d /var/lib/pihole/etc-dnsmasq.d 0750 root root -"
    ];

    sops.secrets.pihole-web-password = {
        sopsFile = "${inputs.self}/secrets/secrets.yaml";
    };

    sops.templates."pihole.env".content = ''
        FTLCONF_webserver_api_password=${config.sops.placeholder.pihole-web-password}
    '';

    virtualisation.oci-containers.containers.pihole = {
        image = "docker.io/pihole/pihole:2026.06.0";
        autoStart = true;
        environment = {
            TZ = "America/Toronto";
            FTLCONF_dns_upstreams = "127.0.0.1#5335";
            FTLCONF_dns_listeningMode = "all";
            FTLCONF_webserver_api_max_sessions = "32";
            FTLCONF_webserver_session_timeout = "900";
        };
        environmentFiles = [
            config.sops.templates."pihole.env".path
        ];
        volumes = [
            "/var/lib/pihole/etc-pihole:/etc/pihole"
            "/var/lib/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
        ];
        extraOptions = [ "--network=host" ];
    };

    systemd.services."podman-pihole" = {
        after = [ "unbound.service" "sops-nix.service" "tailscaled.service" ];
        requires = [ "unbound.service" ];
    };
}
