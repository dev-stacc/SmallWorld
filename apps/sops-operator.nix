{ kubenix, ... } : {
    imports = [
        kubenix.modules.k8s
    ];

    kubernetes.resources = {
        namespaces.sops = {};
    };
}
