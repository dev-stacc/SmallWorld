{
    input = {
        kb_layout = "ca";
        kb_variant = "fr";
    };

    device = [
        {
            name = "hid-04d9:a0be";
            kb_layout = "us,ca";
            kb_variant = ",fr";
        }
        {
            name = "hid-04d9:a0be-mouse";
            scroll_method = "on_button_down";
            scroll_button = 274;
            scroll_button_lock = 0;
        }
        {
            name = "trackball";
            scroll_method = "on_button_down";
            scroll_button = 274;
            scroll_button_lock = 0;
        }
    ];
}
