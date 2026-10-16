{ config, lib, pkgs, ... } : {
    sops = {
        secrets.llama-api-key.sopsFile = ../../../../../secrets/secrets.yaml;

        templates."llama.env" = {
            restartUnits = [ "llama-cpp.service" ];
            content = ''
                LLAMA_API_KEY=${config.sops.placeholder.llama-api-key}
            '';
        };
    };

    services.llama-cpp = {
        enable = true;
        package = pkgs.llama-cpp-vulkan;
        openFirewall = false;
        settings = {
            model = "/mnt/models/gpt-oss-20b-Q4_K_M.gguf";
            host = "0.0.0.0";
            port = 8080;
            alias = "gpt-oss-20b";
            ctx-size = 32768;
            parallel = 1;
            batch-size = 512;
            ubatch-size = 128;
            flash-attn = "on";
            cache-type-k = "q8_0";
            cache-type-v = "q8_0";
            tensor-split = "0.56,0.44";
            cont-batching = true;
            metrics = true;
        };
    };

    systemd.services.llama-cpp = {
        unitConfig.RequiresMountsFor = [ "/mnt/models" ];

        serviceConfig = {
            SupplementaryGroups = [ "video" "render" ];
            RestartSec = lib.mkForce 15;
            EnvironmentFile = config.sops.templates."llama.env".path;
        };

        environment.MESA_SHADER_CACHE_DIR = "/var/cache/llama-cpp/mesa";
    };
}
