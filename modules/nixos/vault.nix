{ config, pkgs, ... } : {
    sops.secrets.vault-unseal-key-1 = {
        sopsFile = ../../secrets/secrets.yaml;
        owner = "root";
    };

    sops.secrets.vault-unseal-key-2 = {
        sopsFile = ../../secrets/secrets.yaml;
        owner = "root";
    };

    systemd.services.vault-unseal = {
        description = "Auto-unseal Vault";
        after = [
            "k3s.service"
            "network-online.target"
            "sops-nix.service"
        ];
        wants = [ "network-online.target" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = false;
            Restart = "on-failure";
            RestartSec = "30s";
            ExecStart = pkgs.writeShellScript "vault-unseal" ''
                export VAULT_ADDR="http://vault.vault.svc.cluster.local:8200"
                export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

                until ${pkgs.kubectl}/bin/kubectl get pod vault-0 -n vault &>/dev/null; do
                  echo "Waiting for vault pod..."
                  sleep 10
                done

                until ${pkgs.vault}/bin/vault status &>/dev/null; do
                  echo "Waiting for vault to be reachable..."
                  sleep 5
                done

                SEALED=$(${pkgs.vault}/bin/vault status -format=json | ${pkgs.jq}/bin/jq -r '.sealed')

                if [ "$SEALED" = "true" ]; then
                  echo "Vault is sealed, unsealing..."
                  ${pkgs.vault}/bin/vault operator unseal $(cat ${config.sops.secrets.vault-unseal-key-1.path})
                  ${pkgs.vault}/bin/vault operator unseal $(cat ${config.sops.secrets.vault-unseal-key-2.path})
                  echo "Vault unsealed"
                else
                  echo "Vault already unsealed"
                fi
            '';
            Environment = [
                "KUBECONFIG=/etc/rancher/k3s/k3s.yaml"
            ];
        };
    };

    systemd.timers.vault-unseal = {
        description = "Ru vault-unseal periodically";
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnBootSec = "2min";
            OnUnitInactiveSec = "5min";
            Unit = "vault-unseal.service";
        };
    };
}
