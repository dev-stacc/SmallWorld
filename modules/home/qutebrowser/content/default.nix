{ config, lib, pkgs, ... } : let
    colors = config.lib.stylix.colors;
    generatedColors = pkgs.writeText "stylix-colors.css" ''
        :root {
            --base00: #${colors.base00};
            --base00-transparent: #${colors.base00};
            --base01: #${colors.base01};
            --base02: #${colors.base02};
            --base03: #${colors.base03};
            --base04: #${colors.base04};
            --base05: #${colors.base05};
            --base06: #${colors.base06};
            --base07: #${colors.base07};
            --base08: #${colors.base08};
            --base09: #${colors.base09};
            --base0A: #${colors.base0A};
            --base0B: #${colors.base0B};
            --base0C: #${colors.base0C};
            --base0D: #${colors.base0D};
            --base0E: #${colors.base0E};
            --base0F: #${colors.base0F};
        }
    '';
    
    userCss = builtins.readFile ./user-stylesheets.css;
    
    finalCss = pkgs.writeText "assembled-user-stylesheet.css" ''
        ${builtins.readFile generatedColors}
        ${userCss}
    '';
    finalCssPath = builtins.toString finalCss;
in  {
    content = lib.mkForce {
        autoplay = false;
        cookies.accept = "no-3rdparty";
        dns_prefetch = false;
        geolocation = false;
        canvas_reading = false;
        notifications.enabled = false;
        webgl = false;
        
        headers = {
            do_not_track = true;
            referer = "same-domain";
            user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36";
        };
        
        user_stylesheets = lib.mkForce [ "${finalCss}" ];
    };
}