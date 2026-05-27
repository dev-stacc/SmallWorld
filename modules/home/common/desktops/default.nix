{ inputs, ... }: {
    imports = [
        inputs.nixcord.homeModules.nixcord
        ./cursors/default.nix
        ./fonts.nix
        ./hyprland/default.nix
        ./nixcord/default.nix
        ./qutebrowser/default.nix
        ./hyprpaper.nix
        ./mako.nix
        ./terminal/default.nix
        ./waybar/default.nix
    ];
}
