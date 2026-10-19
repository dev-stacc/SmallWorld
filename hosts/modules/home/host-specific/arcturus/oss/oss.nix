{ pkgs, agent } : pkgs.writeShellApplication {
    name = "oss";

    runtimeInputs = with pkgs; [ coreutils curl jq util-linux ];

    text = builtins.replaceStrings
        [ "@agent@" ]
        [ "${agent}/bin/oss-agent" ]
        (builtins.readFile ./oss.sh);
}
