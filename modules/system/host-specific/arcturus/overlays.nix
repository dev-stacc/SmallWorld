{ config, pkgs, inputs, ... } : {
    nixpkgs.overlays = [
        inputs.claude-code.overlays.default
        inputs.nur.overlays.default
    ];
}
