{ pkgs, ... } : let
    gpuTempScript = pkgs.writeShellScript "gpu-temp" (builtins.readFile ./scripts/gpu-temp.sh);
    gpuFanScript = pkgs.writeShellScript "gpu-fan" (builtins.readFile ./scripts/gpu-fan.sh);
in {
    home.file = {
        ".local/bin/gpu-temp" = {
            source = gpuTempScript;
            executable = true;
        };
        ".local/bin/gpu-fan" = {
            source = gpuFanScript;
            executable = true;
        };
    };

    programs.waybar.settings.mainBar = {
        "group/thermals" = {
            orientation = "horizontal";
            modules = ["custom/cpu-temp" "custom/gpu-temp" "custom/gpu-fan"];
        };

        "custom/gpu-temp" = {
            exec = "${gpuTempScript}";
            format = "{}°c";
            interval = 2;
            tooltip = false;
        };

        "custom/gpu-fan" = {
            exec = "${gpuFanScript}";
            format = "{} 󰵃 ";
            interval = 3;
            tooltip = false;
        };
    };
}
