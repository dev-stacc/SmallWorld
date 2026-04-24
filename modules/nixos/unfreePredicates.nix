{ config, pkgs, inputs, ... } : {
    nixpkgs.config.allowUnfreePredicate = pkg : builtins.elem
        (pkgs.lib.getName pkg) [
            "claude-code"
        ];
}
