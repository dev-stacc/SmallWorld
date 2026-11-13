{ lib, tailnet } :
let
    classes = {
        asta      = "critical";
        aperture  = "critical";
        albireo   = "critical";
        argus     = "critical";
        amateus   = "critical";
        arcturus  = "watch";
        altair    = "watch";
        alula     = "ignore";
        avior     = "ignore";
    };

    ports = { };

    reachable = lib.filterAttrs
        (name: _: tailnet.ips.${name} != "PLACEHOLDER")
        classes;

    hosts = lib.mapAttrs (name: class: {
        ip = tailnet.ips.${name};
        class = class;
    } // lib.optionalAttrs (lib.hasAttr name ports) {
        port = ports.${name};
    }) reachable;

    clusterApp = auth: name: role: {
        inherit name auth role;
        url = "https://${name}.${tailnet.domain}/";
        label = "${name}.${tailnet.domain}";
        nav = true;
    };

    titledApp = auth: host: name: role:
        (clusterApp auth host role) // { inherit name; };

    hostPage = name: role: host: path: {
        inherit name role;
        auth = false;
        url = "https://${host}.${tailnet.domain}${path}";
        label = "${host}.${tailnet.domain}${lib.optionalString (path != "/") path}";
        nav = true;
        alert = false;
    };

    grouped = group: apps: map (app: app // { inherit group; }) apps;

    offsitePihole = {
        name = "argus";
        role = "off-site dns";
        url = "http://argus.${tailnet.domain}:8081/admin";
        label = "argus.${tailnet.domain}:8081";
        auth = false;
        nav = true;
        alert = true;
    };

    comfort = grouped "comfort" [
        (clusterApp false "search" "search")
        (clusterApp true "chat" "local ai")
        (clusterApp true "jellyfin" "streaming")
        (clusterApp false "forge" "git")
        (clusterApp true "navidrome" "music")
        (clusterApp false "audiobooks" "books")
        (hostPage "pihole" "dns" "pihole" "/admin")
        offsitePihole
        (clusterApp true "wikipedia" "-")
        (clusterApp true "sewing" "-")
        (clusterApp true "marketing" "-")
    ];

    identity = grouped "identity" [
        (clusterApp false "nextcloud" "storage")
        (titledApp false "immich" "Immich" "photos")
        (clusterApp false "authentik" "login")
        (clusterApp false "vault" "secrets")
    ];

    monitoring = grouped "monitoring" [
        (hostPage "flux" "fleet" "home" "/flux")
        (hostPage "k8s" "cluster" "home" "/k8s")
        (hostPage "backups" "-" "home" "/backups")
        (clusterApp true "grafana" "metrics")
    ];

    hidden = [{
        name = "loki";
        url = "http://${tailnet.ips.loki}:3100/nginx-health";
        label = "loki.${tailnet.domain}:3100";
        role = "logs";
        auth = false;
        nav = false;
    } {
        name = "crowdsec";
        url = "http://${tailnet.ips.crowdsec}:8080/health";
        label = "crowdsec.${tailnet.domain}:8080";
        role = "security";
        auth = false;
        nav = false;
    }];

    agentHosts = [ "asta" "aperture" "albireo" "amateus" "altair" ];

    agentPort = 9848;
in {
    inherit classes hosts;

    apps = comfort ++ identity ++ monitoring ++ hidden;

    expectedBackups = [
        {
            host = "albireo";
            paths = [
                "/bigstorage/nextcloud/html"
                "/bigstorage/nextcloud/dumps"
                "/bigstorage/important"
                "/bigstorage/immich/library"
                "/bigstorage/immich/dumps"
            ];
        }
        {
            host = "asta";
            paths = [
                "/var/lib/rancher/k3s/storage"
                "/var/lib/cluster-dumps"
                "/home/anastasia/jellyfin-config"
            ];
        }
        {
            host = "aperture";
            paths = [ "/var/lib/rancher/k3s/storage" "/var/lib/cluster-dumps" ];
        }
        {
            host = "albireo";
            paths = [ "/var/lib/rancher/k3s/storage" "/var/lib/cluster-dumps" ];
        }
    ];

    backupStaleHours = 36;

    resticRepo = "amateus:/srv/restic";

    agents = map (name: {
        host = name;
        url = "http://${tailnet.ips.${name}}:${toString agentPort}";
        priority = classes.${name};
    }) agentHosts;
}
