{ pkgs, agent, aliases } : let
    lib = pkgs.lib;

    arms = lib.concatStringsSep "\n        " (lib.mapAttrsToList
        (name: target: "${name}) model=${target} ;;") aliases);
in pkgs.writeShellApplication {
    name = "oss";

    runtimeInputs = with pkgs; [ coreutils curl jq util-linux ];

    text = builtins.replaceStrings
        [ "@agent@" "@aliasArms@" ]
        [ "${agent}/bin/oss-agent" arms ]
        (builtins.readFile ./oss.sh);
}
