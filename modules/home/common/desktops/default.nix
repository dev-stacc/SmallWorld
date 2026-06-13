{ inputs, ... }: {
    imports = [
        inputs.nixcord.homeModules.nixcord
        ./cursors/default.nix
        ./fonts.nix
        ./nixcord/default.nix
        ./qutebrowser/default.nix
        ./mako.nix
        ./terminal/default.nix
        ./waybar/default.nix
    ];
}
