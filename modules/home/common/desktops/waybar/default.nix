{ config, pkgs, fontName, ... } : let
    cpuBarsScript = pkgs.writeShellScript "cpu-bars" (builtins.readFile ./scripts/cpu-bars.sh);
    cpuTempsScript = pkgs.writeShellScript "cpu-temps" (builtins.readFile ./scripts/cpu-temps.sh);
    micMuteScript = pkgs.writeShellScript "mic-mute" (builtins.readFile ./scripts/mic-mute.sh);
    colors = config.stylix.base16Scheme;
    styles = builtins.readFile ./style.css;

    finalCss = pkgs.writeText "waybar-stylesheet.css" ''
        * {
            font-family:
                "${fontName}",
                "JetBrainsMono Nerd Font",
                monospace;
            font-size: 15px;
        }
        ${styles}
    '';
in {
    home.file = {
        ".local/bin/cpu-bars" = {
            source = cpuBarsScript;
            executable = true;
        };
        ".local/bin/cpu-temps" = {
            source = cpuTempsScript;
            executable = true;
        };
        ".local/bin/mic-mute" = {
            source = micMuteScript;
            executable = true;
        };
    };

    programs.waybar = {
        enable = true;
        package = pkgs.waybar;

        systemd.enable = true;
        style = finalCss;
        
        settings = {
            mainBar = {
                layer = "top";
                position = "top";
                margin-right = 36;
                margin-left = 36;
                
                modules-left = [
                    "group/cpu-usage"
                    "group/thermals"
                    "memory"
                ];
                
                modules-center = [
                    "group/audio"
                    "backlight"  
                    "hyprland/workspaces"
                    "clock"
                ];
                
                modules-right = [
                    "custom/tailscale"
                    "network"
                    "bluetooth"
                    "battery"
                ];
                
                "group/cpu-usage" = {
                    orientation = "horizontal";
                    modules = ["cpu" "custom/cores"];
                };

                "group/audio" = {
                    orientation = "horizontal";
                    modules = ["wireplumber" "custom/mic"];
                };
                                
                cpu = {
                    format = "{usage}%";
                    interval = 1;
                    tooltip = false;
                };
                
                "custom/cores" = {
                    exec = "${cpuBarsScript}";
                    format = "{}";
                    interval = 1;
                    tooltip = false;
                };
                
                temperature = {
                    exec = "${cpuTempsScript}";
                    format = "{}°c";
                    interval = 2;
                    tooltip = false;
                };

                "memory" = {
                    interval = 30;
                    format = "{used}/{total}  ";
                    tooltip = false;
                };

                battery = {
                    format = "{capacity}% {icon}";
                    format-icons = [
                        "󰁺" "󰁻" "󰁼" "󰁽" "󰁾"
                        "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"
                    ];
                };

                "wireplumber" = {
                    format = "{volume} {icon}";
                    format-muted = "󰝟 muted";
                    format-icons = ["󰕿 " "󰖀 " "󰕾 " " "];
                    tooltip = false;
                };

                "custom/mic" = { 
                    exec = "${micMuteScript}";
                    interval = 1;
                    tooltip = false;
                };

                backlight = {
                    format = "{percent} {icon}";
                    format-icons = ["󱩎 " "󱩏 " "󱩐 " "󱩐 " "󱩒 " "󱩓 " "󱩔 " "󱩕 " "󱩖 "];
                    tooltip = false;
                };

                "clock" = {
                    format = "{0:%d/%m/%Y} 󰃭    {0:%H:%M}  ";
                    tooltip = false;
                };

                "custom/tailscale" = {
                    "exec" = "tailscale status >/dev/null 2>&1 && echo ' 󰒘 '|| echo ' 󰒙 '";
                    "interval" = 3;
                    "tooltip" = false;
                };

                "network" = {
                    "format-wifi" = "{bandwidthDownBits} {bandwidthUpBits}";
                    "format-ethernet" = "{bandwidthDownBits} {bandwidthUpBits}";
                    "format-disconnected" = "󰤭 ";
                    "format-disabled" = "󰤭 ";
                    "tooltip" = false;
                };
                
                "bluetooth" = {
                    "format" = "{icon}";
                    "format-on" = " ";
                    "format-connected" = "{device_alias}  ";
                    "format-disabled" = "󰂯";
                    "format-off" = "󰂯";
                    "tooltip" = false;
                };
            };
        };
    };
}
