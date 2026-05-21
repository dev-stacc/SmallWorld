{ fontName, fontSize, ... }: let
    font = "${builtins.toString fontSize}pt ${fontName}";
in {
    fonts = {
        default_family = fontName;
        default_size = "${builtins.toString fontSize}pt";

        completion.entry = font;
        completion.category = font;
        statusbar = font;
        tabs.selected = font;
        tabs.unselected = font;
        hints = font;
        prompts = font;
        messages.error = font;
        messages.info = font;
        messages.warning = font;
        keyhint = font;
        contextmenu = font;
        tooltip = font;
    };
}
