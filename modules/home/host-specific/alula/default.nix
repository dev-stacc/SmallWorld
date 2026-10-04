# Mobile, easy to steal: deliberately kept thin. Browsing/terminal/editor/files
# only, with the shared themed librewolf as the single browser (same setup as
# arcturus). No gh token on disk; no discord.
{ pkgs, ... } : {
    imports = [
        ./sway/default.nix
        ./waybar/default.nix
    ];

    home.packages = with pkgs; [
        claude-code
    ];
}
