{ config, pkgs, inputs, ... } : {
    nixpkgs.config.allowUnfreePredicate = pkg : builtins.elem
        (pkgs.lib.getName pkg) [
            "claude-code"
            "discord"
            "steam"
            "steam-original"
            "steam-unwrapped"
            "steam-run"
        ];
}
