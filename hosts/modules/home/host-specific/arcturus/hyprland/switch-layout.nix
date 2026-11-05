{ pkgs } : pkgs.writeShellApplication {
    name = "switch-layout";

    runtimeInputs = with pkgs; [ hyprland jq libnotify ];

    text = ''
        device=hid-04d9:a0be

        hyprctl switchxkblayout "$device" next > /dev/null

        layout=$(hyprctl -j devices | jq -r \
            --arg d "$device" \
            '.keyboards[] | select(.name == $d) | .active_keymap')

        notify-send -a switch-layout "Keyboard layout" "$layout"
    '';
}
