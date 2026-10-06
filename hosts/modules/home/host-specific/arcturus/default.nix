{ inputs, pkgs, ... } : {
    imports = [
        inputs.nixcord.homeModules.nixcord
        ./nixcord/default.nix
        ./hyprland/default.nix
        ./hyprpaper.nix
        ./k3s-control/default.nix
        ./ssh.nix
        ./waybar/default.nix
    ];
    
    home.packages = with pkgs; [
        claude-code
        libreoffice
    ];

    programs.bash.shellAliases.hyprland = "exec Hyprland";
}
