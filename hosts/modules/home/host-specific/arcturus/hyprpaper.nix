{ pkgs, theme, ... } : {
    home.packages = with pkgs; [
        hyprpaper
    ];

    services.hyprpaper = {
        enable = true;
        settings = {
            splash = false;

            preload = [
                "${theme.wallpaper}"
            ];
            wallpaper = [{
                monitor = "";
                path = "${theme.wallpaper}";
            }];
        };
    };
}
