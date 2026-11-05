{ pkgs, theme, settings } : pkgs.writeShellApplication {
    name = "qwen";

    runtimeInputs = with pkgs; [
        coreutils curl jq util-linux git ripgrep fd kubectl fluxcd yq-go
        systemd iproute2 dnsutils
    ];

    text = builtins.replaceStrings
        [ "@qwen@" "@settings@" "@system@" "@dim@" "@warn@" "@error@" ]
        [
            "${pkgs.qwen-code}/bin/qwen"
            "${settings}"
            "${./system.md}"
            theme.base16.base02
            theme.base16.base04
            theme.base16.base03
        ]
        (builtins.readFile ./qwen.sh);
}
