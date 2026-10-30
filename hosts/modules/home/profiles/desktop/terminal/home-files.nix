{ pkgs, tailnet, ... } : let
    kittyLauncher = pkgs.writeShellScript "kitty-launcher" (builtins.readFile ./raw-files/kitty-launcher.sh);

    kittyControl = pkgs.writeShellScript "kitty-control" (builtins.replaceStrings
        [ "{{sanctuaryIp}}" "{{argusIp}}" ]
        [ tailnet.ips.sanctuary tailnet.ips.argus ]
        (builtins.readFile ./raw-files/kitty-control.sh));
in { 
    home.file = {
        ".local/bin/kitty-launcher" = {
            source = kittyLauncher;
            executable = true;
        };
        ".local/bin/kitty-control" = {
            source = kittyControl;
            executable = true;
        };
        ".config/xdg-desktop-portal-termfilechooser/config" = {
            text = ''
                [filechooser]
                cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
                default_dir=$HOME
            '';
        };
    };
}
