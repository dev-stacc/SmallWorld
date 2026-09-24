{
    enable = true;

    settings = {
        # Render while reading and navigating, but drop back to raw source in
        # insert mode so editing never fights the concealed text.
        render_modes = [ "n" "c" "t" "v" "V" ];

        signs.enabled = false;

        heading = {
            sign = false;
            position = "inline";
            width = "block";
            left_pad = 0;
            right_pad = 2;
            icons = [ "󰲡 " "󰲣 " "󰲥 " "󰲧 " "󰲩 " "󰲫 " ];
        };

        code = {
            sign = false;
            width = "block";
            position = "right";
            language_pad = 2;
            left_pad = 2;
            right_pad = 2;
            border = "thick";
        };

        bullet = {
            icons = [ "◆" "•" "▸" "▹" ];
            right_pad = 1;
        };

        checkbox = {
            unchecked.icon = "󰄱 ";
            checked.icon = "󰱒 ";
        };

        pipe_table = {
            preset = "round";
            alignment_indent = false;
        };
    };
}
