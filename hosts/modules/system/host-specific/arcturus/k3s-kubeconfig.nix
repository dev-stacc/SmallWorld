{ ... } : {
    sops.secrets.k3s-kubeconfig = {
        key = "k3s-kubeconfig-admin";
        sopsFile = ../../../../../secrets/secrets.yaml;
        owner = "anastasia";
        group = "users";
        mode = "0400";
    };
}
