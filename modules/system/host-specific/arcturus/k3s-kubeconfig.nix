{ ... } : {
    sops.secrets.k3s-kubeconfig = {
        sopsFile = ../../../../secrets/secrets.yaml;
        owner = "anastasia";
        group = "users";
        mode = "0400";
    };
}
