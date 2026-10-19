{ ... } : {
    sops.secrets.llama-api-key = {
        sopsFile = ../../../../../secrets/secrets.yaml;
        owner = "anastasia";
        group = "users";
        mode = "0400";
    };
}
