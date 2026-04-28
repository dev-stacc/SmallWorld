{ pkgs, lib, config, ... } : let
    kittyLauncher = pkgs.writeShellScript "kitty-launcher" (builtins.readFile ./raw-files/kitty-launcher.sh);
    kittyControl = pkgs.writeShellScript "kitty-control" (builtins.readFile ./raw-files/kitty-control.sh);
    kittyExplorer = pkgs.writeText "kitty-explorer" (builtins.readFile ./raw-files/kitty-explorer.desktop);
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
        ".local/share/applications/kitty-explorer.desktop" = {
            source = kittyExplorer;
        };
    };
}
