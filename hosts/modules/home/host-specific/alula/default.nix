# Mobile, easy to steal: deliberately kept thin. Browsing/terminal/editor/files
# only, with the shared themed librewolf as the single browser (same setup as
# arcturus). No gh token on disk; no discord.
{ ... } : {
    imports = [
        ../../profiles/desktop/waybar/default.nix
        ./sway/default.nix
        ./waybar/default.nix
    ];

    programs.bash.shellAliases.sway = "exec sway";
}
