{ pkgs, config, ... } : {
    home-manager.users.anastasia = {
        home.username = "anastasia";
        home.homeDirectory = "/home/anastasia";
        home.stateVersion = "25.11";
        programs.home-manager.enable = true;
    
        imports = [
            ./hyprland/default.nix
            ./kitty/default.nix
            ./wayland/default.nix
            ./programs/default.nix
            ./qutebrowser/default.nix
        ];
    };
}