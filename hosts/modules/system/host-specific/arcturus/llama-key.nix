{ ... } : let
    secret = {
        sopsFile = ../../../../../secrets/secrets.yaml;
        owner = "anastasia";
        group = "users";
        mode = "0400";
    };
in {
    sops.secrets = {
        llama-api-key = secret;
        oss-agent-kubeconfig = secret;
    };
}
