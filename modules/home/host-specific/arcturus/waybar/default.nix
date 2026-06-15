{ pkgs, ... } : let
    fanScript = pkgs.writeShellScript "fan-speed" (builtins.readFile ./scripts/fan-speed.sh);
in {
    home.file.".local/bin/fan-speed" = {
        source = fanScript;
        executable = true;
    };

    programs.waybar.settings.mainBar = {
        "group/thermals" = {
            orientation = "horizontal";
            modules = ["temperature" "custom/fan"];
        };

        "custom/fan" = {
            exec = "${fanScript}";
            format = "{} 󰵃 ";
            interval = 3;
            tooltip = false;
        };
    };
}
