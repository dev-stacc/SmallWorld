{ config, ... } : {
    home.file.".kube/config".source =
        config.lib.file.mkOutOfStoreSymlink "/run/secrets/k3s-kubeconfig";
}
