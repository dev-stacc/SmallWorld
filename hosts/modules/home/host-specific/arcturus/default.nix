{ inputs, pkgs, ... } : {
    imports = [
        inputs.nixcord.homeModules.nixcord
        ./nixcord/default.nix
        ./hyprland/default.nix
        ./eww/default.nix
        ./hyprpaper.nix
        ./k3s-control/default.nix
        ./coder/default.nix
        ./oss/default.nix
        ./qwen/default.nix
        ./quickshell/default.nix
        ./ssh.nix
    ];
    
    home.packages = with pkgs; [
        libreoffice
    ];

    programs.bash.shellAliases.hyprland = "exec Hyprland";
}
