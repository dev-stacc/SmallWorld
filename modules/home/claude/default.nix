{ config, lib, pkgs, ... } : {
    home.packages = with.pkgs; [
        inputs.claude-code-nix.packages.${pkgs.system}.default
    ];

    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem
        (lib.getName pkg) [
        "claude-code"
    ];
}
