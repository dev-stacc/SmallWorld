{ config, lib, pkgs, ... } : let
    modelDir = "/mnt/models";

    common = lib.concatStringsSep " " [
        "${pkgs.llama-cpp-vulkan}/bin/llama-server"
        "--host 127.0.0.1"
        "--port \${PORT}"
        "--no-webui"
        "--jinja"
        "--metrics"
        "--parallel 1"
        "--cont-batching"
        "--batch-size 512"
        "--ubatch-size 128"
        "--flash-attn on"
        "--cache-reuse 256"
        "--slot-save-path /var/cache/llama-swap/slots"
    ];

    qwenSampling = "--temp 0.7 --top-p 0.8 --top-k 20 --repeat-penalty 1.05";

    coderModel = "--model ${modelDir}/Qwen3-Coder-30B-A3B-Instruct-UD-Q3_K_XL.gguf";

    kv8 = "--cache-type-k q8_0 --cache-type-v q8_0";

    kv4 = "--cache-type-k q4_0 --cache-type-v q4_0";

    cmd = parts: lib.concatStringsSep " " ([ common ] ++ parts);
in {
    sops = {
        secrets.llama-api-key.sopsFile = ../../../../../secrets/secrets.yaml;

        templates."llama.env" = {
            restartUnits = [ "llama-swap.service" ];
            content = ''
                LLAMA_API_KEY=${config.sops.placeholder.llama-api-key}
            '';
        };
    };

    services.llama-swap = {
        enable = true;
        package = pkgs.llama-swap-minimal;
        listenAddress = "0.0.0.0";
        port = 8080;
        openFirewall = false;

        settings = {
            apiKeys = [ "\${env.LLAMA_API_KEY}" ];
            healthCheckTimeout = 900;
            globalTTL = 0;
            sendLoadingState = true;

            hooks.on_startup.preload = [ "qwen3-coder" ];

            models = {
                "gpt-oss-20b-uncensored" = {
                    name = "gpt-oss 20B abliterated";
                    description = "Default. Uncensored MoE, 3.6B active, fastest here at 43 tok/s";
                    cmd = cmd [
                        "--model ${modelDir}/huihui-ai_Huihui-gpt-oss-20b-BF16-abliterated-MXFP4_MOE.gguf"
                        "--alias gpt-oss-20b-uncensored"
                        "--ctx-size 32768"
                        kv8
                        "--tensor-split 0.56,0.44"
                        "--spec-type ngram-simple"
                    ];
                };

                "qwen3.6-uncensored" = {
                    name = "Qwen3.6 35B-A3B abliterated";
                    description = "Uncensored. MoE, 3B active";
                    filters.stripParams = "chat_template_kwargs";
                    cmd = cmd [
                        "--model ${modelDir}/Huihui-Qwen3.6-35B-A3B-abliterated.Q2_K.gguf"
                        "--alias qwen3.6-uncensored"
                        "--ctx-size 32768"
                        kv8
                    ];
                };

                "qwen3-coder" = {
                    name = "Qwen3-Coder 30B-A3B";
                    description = "Coding. MoE, 3.3B active, UD-Q3_K_XL";
                    filters.stripParams = "chat_template_kwargs";
                    cmd = cmd [
                        "--model ${modelDir}/Qwen3-Coder-30B-A3B-Instruct-UD-Q3_K_XL.gguf"
                        "--alias qwen3-coder"
                        "--tensor-split 0.50,0.50"
                        "--spec-type ngram-simple"
                        "--ctx-size 32768"
                        kv8
                        qwenSampling
                    ];
                };

                "qwen3-coder-fast" = {
                    name = "Qwen3-Coder 30B-A3B (small)";
                    description = "Coding. UD-Q2_K_XL, full context, lower quality";
                    filters.stripParams = "chat_template_kwargs";
                    cmd = cmd [
                        "--model ${modelDir}/Qwen3-Coder-30B-A3B-Instruct-UD-Q2_K_XL.gguf"
                        "--alias qwen3-coder-fast"
                        "--ctx-size 32768"
                        kv8
                        qwenSampling
                    ];
                };









                "qwen3-coder-max" = {
                    name = "Qwen3-Coder 30B-A3B (overnight)";
                    description = "Overnight. UD-Q5_K_XL with experts in RAM, ~10 tok/s, best quality here";
                    filters.stripParams = "chat_template_kwargs";
                    cmd = cmd [
                        "--model ${modelDir}/Qwen3-Coder-30B-A3B-Instruct-UD-Q5_K_XL.gguf"
                        "--alias qwen3-coder-max"
                        "--ctx-size 32768"
                        kv4
                        "--tensor-split 0.50,0.50"
                        "--n-cpu-moe 16"
                        "--spec-type ngram-simple"
                        qwenSampling
                    ];
                };
            };
        };
    };

    systemd.services.llama-swap = {
        unitConfig.RequiresMountsFor = [ modelDir ];

        serviceConfig = {
            EnvironmentFile = config.sops.templates."llama.env".path;

            ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /var/cache/llama-swap/slots";
        };

        environment.MESA_SHADER_CACHE_DIR = "/var/cache/llama-swap/mesa";
    };
}
