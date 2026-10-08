{ lib, pkgs, ... } : {
    services.llama-cpp = {
        enable = true;
        package = pkgs.llama-cpp-vulkan;
        openFirewall = false;
        settings = {
            model = "/mnt/models/Qwen3-14B-Q5_K_M.gguf";
            host = "0.0.0.0";
            port = 8080;
            alias = "qwen3-14b";
            n-gpu-layers = 999;
            split-mode = "layer";
            tensor-split = "1,1";
            ctx-size = 8192;
            batch-size = 512;
            ubatch-size = 128;
            cont-batching = true;
            metrics = true;
        };
    };

    systemd.services.llama-cpp = {
        unitConfig.RequiresMountsFor = [ "/mnt/models" ];

        serviceConfig = {
            SupplementaryGroups = [ "video" "render" ];
            RestartSec = lib.mkForce 15;
        };

        environment.MESA_SHADER_CACHE_DIR = "/var/cache/llama-cpp/mesa";
    };
}
