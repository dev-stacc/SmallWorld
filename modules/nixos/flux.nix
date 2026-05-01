{ config, pkgs, ... } : {
    systemd.services.flux-bootstrap = {
        description = "Bootstrap Flux CD";
        after = [ "k3s.service" "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "flux-bootstrap" ''
                until ${pkgs.kubectl}/bin/kubectl get nodes &>/dev/null; do
                    sleep 5
                done

                if ${pkgs.fluxcd}/bin/flux check --pre &>/dev/null; then
                    exit 0
                fi

                ${pkgs.fluxcd}/bin/flux bootstrap github \
                    --owner=<your-github-user> \
                    --repository=BiggerWorld \
                    --branch=main \
                    --path=k8s/flux \
                    --personal \
                    --private
            '';
            Environment = [
                "KUBECONFIG=/etc/rancher/k3s/k3s.yaml"
                "GITHUB_TOKEN=%d/github-token"
            ];
            LoadCredential = "github-token:/run/secrets/github-token";
        };
    };
}
