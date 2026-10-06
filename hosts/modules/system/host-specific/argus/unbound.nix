{ ... } : {
    services.unbound = {
        enable = true;
        resolveLocalQueries = false;
        settings = {
            server = {
                verbosity = 0;
                interface = [ "127.0.0.1" ];
                port = 5335;
                do-ip4 = true;
                do-ip6 = false;
                do-udp = true;
                do-tcp = true;
                harden-glue = true;
                harden-dnssec-stripped = true;
                use-caps-for-id = false;
                edns-buffer-size = 1232;
                prefetch = true;
                num-threads = 1;
                so-rcvbuf = "1m";
                private-address = [
                    "192.168.0.0/16"
                    "169.254.0.0/16"
                    "172.16.0.0/12"
                    "10.0.0.0/8"
                    "fd00::/8"
                    "fe80::/10"
                ];
            };
        };
    };
}
