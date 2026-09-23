{ pkgs, inputs, ... } : {
    imports = [
        inputs.niri.homeModules.niri
        ./bind.nix
        ./general.nix
        ./input.nix
        ./output.nix
        ./window-rule.nix
    ];

    programs.niri = {
        enable = true;
        package = pkgs.niri;
    };
}
