{ kubenix, ... } : {
    imports = [
        kubenix.modules.k8s
    ];

    kubernetes.ressources = {
        namespaces.tailscale = {};

        serviceAccounts.tailscale-operator = {
            metadata.namespace = "tailscale";
        };

        secrets.operator-oauth = {
            metadata.namespace = "tailscale";
            stringData = {
                client_id.$patch = "placeholder";
                client_secret.$patch = "placeholder";
            };
        };
    };
}
