{ pkgs, config, lib, inputs, ... } : {
    home-manager.users.anastasia = {
        home.username = "anastasia";
        home.homeDirectory = "/home/anastasia";
        home.stateVersion = "25.11";
        programs.home-manager.enable = true;

        _module.args = {
            inputs = inputs;
            fontName = lib.mkForce config.stylix.fonts.monospace.name;
            fontSize = lib.mkForce config.stylix.fonts.sizes.terminal;
       };

        imports = [
            inputs.nixvim.homeModules.nixvim
            ./hyprland/default.nix
            ./kitty/default.nix
            ./wayland/default.nix
            ./programs/default.nix
            ./qutebrowser/default.nix
            ./nixvim/default.nix
            ./fonts.nix
            ./services/hyprpaper.nix
        ];

        home.packages = with pkgs; [
            departure-mono
            nerd-fonts.jetbrains-mono
            hyprpaper
            claude-code
            mako
        ];

    };
}
