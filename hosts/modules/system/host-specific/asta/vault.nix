{ pkgs, ... } : {
    environment.systemPackages = with pkgs; [
        vault
        jq
    ];

    sops.secrets.vault-unseal-key-1 = {
        sopsFile = ../../../../../secrets/secrets.yaml;
        owner = "root";
    };

    sops.secrets.vault-unseal-key-2 = {
        sopsFile = ../../../../../secrets/secrets.yaml;
        owner = "root";
    };
}
