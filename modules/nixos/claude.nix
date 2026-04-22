{ config, pkgs, inputs, ... } : {
    nixpkgs = {
        overlays = [ inputs.claude-code.overlays.default ];
        config.allowUnfreePredicate = pkg :
            builtins.elem (pkgs.lib.getName pkg) ["claude-code"];
    };
}
