{ config, lib, pkgs, inputs, ... } : {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem
        (lib.getName pkg) [
            "claude-code"
            "discord"
            "steam"
            "steam-original"
            "steam-unwrapped"
            "steam-run"
            "vault"
        ];
}
