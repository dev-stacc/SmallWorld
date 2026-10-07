{ config, tailnet, ... } : {
    sops.secrets.crowdsec-firewall-bouncer-api-key = {
        sopsFile = ../../../../../secrets/secrets.yaml;
    };

    services.crowdsec-firewall-bouncer = {
        enable = true;
        secrets.apiKeyPath =
            config.sops.secrets.crowdsec-firewall-bouncer-api-key.path;
        settings.api_url = "http://${tailnet.ips.crowdsec}:8080";
    };
}
