{ config, ... } : {
    services.hyprpaper = {
        enable = true;
        settings = {
            preload = [
                config.stylix.image
            ];
            wallpaper = [{
                monitor = "";
                path = config.stylix.image;
            }];
        };
    };
}