{ lib, pkgs, ... } : let
    modelDir = "/mnt/models";

    models = {
        "Qwen3-14B-Q5_K_M.gguf" = {
            repo = "Qwen/Qwen3-14B-GGUF";
            rev = "530227a7d994db8eca5ab5ced2fb692b614357fd";
            sha256 = "e7c9aba1129ca2936be9eca01419d9f86af40e08caa01230d5574b34d08e3e31";
            size = "10514569568";
        };

        "Qwen3-8B-Q5_K_M.gguf" = {
            repo = "Qwen/Qwen3-8B-GGUF";
            rev = "7c41481f57cb95916b40956ab2f0b139b296d974";
            sha256 = "068bae163faa96ad48032daf4e071a6a28fe67d8dcc95367609c2ff165e52738";
            size = "5851112224";
        };

        "Qwen3.6-35B-A3B-UD-Q2_K_XL.gguf" = {
            repo = "unsloth/Qwen3.6-35B-A3B-GGUF";
            rev = "a483e9e6cbd595906af30beda3187c2663a1118c";
            sha256 = "96b9c0af5c77a4ecaabe3983175112b5ece763261c1ece12b2494b692a70dad7";
            size = "12290628576";
        };

        "gpt-oss-20b-Q4_K_M.gguf" = {
            repo = "unsloth/gpt-oss-20b-GGUF";
            rev = "d449b42d93e1c2c7bda5312f5c25c8fb91dfa9b4";
            sha256 = "c27536640e410032865dc68781d80a08b98f8db5e93575919af8ccc0568aeb4f";
            size = "11624759488";
        };
<<<<<<< Updated upstream
=======

        "huihui-ai_Huihui-gpt-oss-20b-BF16-abliterated-MXFP4_MOE.gguf" = {
            repo = "bartowski/huihui-ai_Huihui-gpt-oss-20b-BF16-abliterated-GGUF";
            rev = "119a7449dd895220548fb3b67f55ef60e01b059c";
            sha256 = "abca50d1bd95c49d71db36aad0f38090ea5465ce148634c496a48bc87030bdd9";
            size = "12109565600";
        };

        "Huihui-Qwen3.6-35B-A3B-abliterated.Q2_K.gguf" = {
            repo = "mradermacher/Huihui-Qwen3.6-35B-A3B-abliterated-GGUF";
            rev = "0693fc2b47f66380f4b568b01e05195d22edd3a2";
            sha256 = "5073fcc761e51afba317bb5af004691ba5f048a4c284d9d2330ef0caea5da224";
            size = "12939594624";
        };

        "Qwen3-Coder-30B-A3B-Instruct-UD-Q3_K_XL.gguf" = {
            repo = "unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF";
            rev = "b17cb02dd882d5b6ab62fc777ad2995f19668350";
            sha256 = "69cd7578d77dffc0b17e34bad9ef998d08ae0e20ccceef21bad4e7eb3d8c553b";
            size = "13806312608";
        };

        "Qwen3-Coder-30B-A3B-Instruct-UD-Q2_K_XL.gguf" = {
            repo = "unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF";
            rev = "b17cb02dd882d5b6ab62fc777ad2995f19668350";
            sha256 = "3dee4686d756e8842aec638c5725666c76584edce76d71088732b52d2c5d7a45";
            size = "11788590240";
        };
>>>>>>> Stashed changes
    };

    fetch = name: { repo, rev, sha256, size }: ''
        if [ ! -e ${modelDir}/${name} ]; then
            if [ "$(stat -c %s ${modelDir}/${name}.part 2>/dev/null || echo 0)" != "${size}" ]; then
                curl --no-progress-meter -fL --retry 10 --retry-delay 30 -C - \
                    -o ${modelDir}/${name}.part \
                    "https://huggingface.co/${repo}/resolve/${rev}/${name}"
            fi

            if ! printf '%s  %s\n' ${sha256} ${modelDir}/${name}.part \
                | sha256sum --quiet -c -; then
                rm -f ${modelDir}/${name}.part
                echo "checksum mismatch for ${name}" >&2
                exit 1
            fi

            mv ${modelDir}/${name}.part ${modelDir}/${name}
            echo "fetched ${name}"
        fi
    '';
in {
    systemd.services.fetch-models = {
        description = "Download declared GGUF models";
<<<<<<< Updated upstream
        wantedBy = [ "multi-user.target" ];
        before = [ "llama-cpp.service" ];
=======
>>>>>>> Stashed changes
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = with pkgs; [ curl coreutils ];
        restartIfChanged = false;

        unitConfig.RequiresMountsFor = modelDir;

        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
        };

        script = lib.concatStrings (lib.mapAttrsToList fetch models);
    };

    systemd.timers.fetch-models = {
        wantedBy = [ "timers.target" ];

        timerConfig = {
            OnBootSec = "3min";
            Unit = "fetch-models.service";
        };
    };
}
