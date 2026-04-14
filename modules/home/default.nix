{ pkgs, config, ... } : {
    home-manager.users.anastasia = {
        home.username = "anastasia";
        home.homeDirectory = "/home/anastasia";
        home.stateVersion = "25.11";
        programs.home-manager.enable = true;
    
        imports = [
            ./hyprland/default.nix
            ./stylix.nix
        ];
    };
}