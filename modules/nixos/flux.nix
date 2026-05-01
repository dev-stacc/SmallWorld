{ config, pkgs, ... }: {
    sops.secrets.ts-operator-client-id = {
        sopsFile = ../../secrets/secrets.yaml;
        owner = "root";
    };

    sops.secrets.ts-operator-client-secret = {
        sopsFile = ../../secrets/secrets.yaml;
        owner = "root";
    };

    systemd.services.tailscale-operator-secret = {
        description = "Create Tailscale operator OAuth secret in Kubernetes";
        after = [ "k3s.service" "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "create-ts-secret" ''
                export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

                until ${pkgs.kubectl}/bin/kubectl get nodes &>/dev/null; do
                    sleep 5
                done

                ${pkgs.kubectl}/bin/kubectl create namespace tailscale \
                    --dry-run=client -o yaml | \
                    ${pkgs.kubectl}/bin/kubectl apply -f -

                ${pkgs.kubectl}/bin/kubectl create secret generic operator-oauth \
                    --namespace tailscale \
                    --from-file=client_id=${config.sops.secrets.ts-operator-client-id.path} \
                    --from-file=client_secret=${config.sops.secrets.ts-operator-client-secret.path} \
                    --dry-run=client -o yaml | \
                    ${pkgs.kubectl}/bin/kubectl apply -f -
            '';
        };
    };
}
