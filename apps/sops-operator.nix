{ kubenix, ... } : {
    imports = [
        kubenix.modules.k8s
    ];

    kubernetes.ressources = {
        namespaces.sops = {};
    };
}
