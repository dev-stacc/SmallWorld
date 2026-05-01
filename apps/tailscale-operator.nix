{ kubenix, ... } : {
    imports = [
        kubenix.modules.k8s
    ];

    kubernetes.resources = {
        namespaces.tailscale = {};

        secrets.operator-oauth = {
            metadata.namespace = "tailscale";
            stringData = {
                client_id = "placeholder";
                client_secret = "placeholders";
            };
        };
    };
}
