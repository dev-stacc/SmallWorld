{ config, pkgs, inputs, ... } : {
    nixpkgs.overlays = [ claude-code.overlays.default ];
    nixpkgs.allowUnfreePredicate = pkg :
        builtins.elem (pkgs.lib.getName pkg) ["claude-code"];
}
