{ lib, pkgs, ... } : {
    services.llama-cpp = {
        enable = true;
        package = pkgs.llama-cpp-vulkan;
        openFirewall = false;
        settings = {
            model = "/mnt/models/Qwen3-8B-Q5_K_M.gguf";
            host = "0.0.0.0";
            port = 8080;
            alias = "qwen3-8b";
            ctx-size = 8192;
            parallel = 1;
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
