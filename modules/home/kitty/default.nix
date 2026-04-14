{ pkgs, lib, config, ... } : let
    kittyLauncher = pkgs.writeShellScript "kitty-launcher" (builtins.readFile ./scripts/kitty-launcher.sh);
    kittyControl = pkgs.writeShellScript "kitty-control" (builtins.readFile ./scripts/kitty-control.sh);
in {
    programs.kitty = {
        enable = true;
        enableGitIntegration = true;
        settings = {
            background_opacity = lib.mkForce "0.6";
        };
    };
  
    home.file = {
        ".local/bin/kitty-launcher" = {
            source = kittyLauncher;
            executable = true;
        };
        ".local/bin/kitty-control" = {
            source = kittyControl;
            executable = true;
        };
    };
}