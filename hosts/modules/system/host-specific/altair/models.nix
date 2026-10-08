{ lib, pkgs, ... } : let
    modelDir = "/mnt/models";

    models = {
        "Qwen3-14B-Q5_K_M.gguf" =
            "https://huggingface.co/Qwen/Qwen3-14B-GGUF/resolve/main/Qwen3-14B-Q5_K_M.gguf";
    };

    fetch = name: url: ''
        if [ ! -e ${modelDir}/${name} ]; then
            curl -fL --retry 10 --retry-delay 30 -C - \
                -o ${modelDir}/${name}.part "${url}"
            mv ${modelDir}/${name}.part ${modelDir}/${name}
        fi
    '';
in {
    systemd.services.fetch-models = {
        description = "Download declared GGUF models";
        wantedBy = [ "multi-user.target" ];
        before = [ "llama-cpp.service" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = with pkgs; [ curl coreutils ];

        unitConfig.RequiresMountsFor = modelDir;

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
        };

        script = lib.concatStrings (lib.mapAttrsToList fetch models);
    };
}
