{ pkgs, config, lib, inputs, ... } : {
    home-manager.users.anastasia = {
        home.username = "anastasia";
        home.homeDirectory = "/home/anastasia";
        home.stateVersion = "25.11";
        programs.home-manager.enable = true;

        _module.args = {
            fontName = lib.mkForce config.stylix.fonts.monospace.name;
            fontSize = lib.mkForce config.stylix.fonts.sizes.terminal;
        };
    
        imports = [
            ./hyprland/default.nix
            ./kitty/default.nix
            ./wayland/default.nix
            ./programs/default.nix
            ./qutebrowser/default.nix
        ];
    };
}