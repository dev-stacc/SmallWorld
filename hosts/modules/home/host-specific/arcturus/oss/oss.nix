{ pkgs, agent, aliases } : let
    lib = pkgs.lib;

    names = lib.concatStringsSep ", " (builtins.attrNames aliases);

    arms = lib.concatStringsSep "\n        " (lib.mapAttrsToList
        (name: target: "${name}) model=${target} ;;") aliases);
in pkgs.writeShellApplication {
    name = "oss";

    runtimeInputs = with pkgs; [ coreutils curl jq util-linux ];

    text = builtins.replaceStrings
        [ "@agent@" "@aliasArms@" "@aliasNames@" ]
        [ "${agent}/bin/oss-agent" arms names ]
        (builtins.readFile ./oss.sh);
}
