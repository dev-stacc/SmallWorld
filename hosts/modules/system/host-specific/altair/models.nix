{ lib, pkgs, ... } : let
    modelDir = "/mnt/models";

    models = {
        "Qwen3-14B-Q5_K_M.gguf" = {
            repo = "Qwen/Qwen3-14B-GGUF";
            rev = "530227a7d994db8eca5ab5ced2fb692b614357fd";
            sha256 = "e7c9aba1129ca2936be9eca01419d9f86af40e08caa01230d5574b34d08e3e31";
        };

        "Qwen3-8B-Q5_K_M.gguf" = {
            repo = "Qwen/Qwen3-8B-GGUF";
            rev = "7c41481f57cb95916b40956ab2f0b139b296d974";
            sha256 = "068bae163faa96ad48032daf4e071a6a28fe67d8dcc95367609c2ff165e52738";
        };

        "Qwen3.6-35B-A3B-UD-Q2_K_XL.gguf" = {
            repo = "unsloth/Qwen3.6-35B-A3B-GGUF";
            rev = "a483e9e6cbd595906af30beda3187c2663a1118c";
            sha256 = "96b9c0af5c77a4ecaabe3983175112b5ece763261c1ece12b2494b692a70dad7";
        };

        "gpt-oss-20b-Q4_K_M.gguf" = {
            repo = "unsloth/gpt-oss-20b-GGUF";
            rev = "d449b42d93e1c2c7bda5312f5c25c8fb91dfa9b4";
            sha256 = "c27536640e410032865dc68781d80a08b98f8db5e93575919af8ccc0568aeb4f";
        };
    };

    fetch = name: { repo, rev, sha256 }: ''
        if [ ! -e ${modelDir}/${name} ]; then
            curl -fL --retry 10 --retry-delay 30 -C - \
                -o ${modelDir}/${name}.part \
                "https://huggingface.co/${repo}/resolve/${rev}/${name}"

            if ! printf '%s  %s\n' ${sha256} ${modelDir}/${name}.part \
                | sha256sum -c -; then
                rm -f ${modelDir}/${name}.part
                echo "checksum mismatch for ${name}" >&2
                exit 1
            fi

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
