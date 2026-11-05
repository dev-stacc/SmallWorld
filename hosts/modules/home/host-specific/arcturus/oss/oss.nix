{ pkgs, agent, aliases } : let
    lib = pkgs.lib;

    names = lib.concatStringsSep ", " (builtins.attrNames aliases);

    pairs = lib.concatStringsSep " " (lib.mapAttrsToList
        (name: target: "\"${name}=${target}\"") aliases);
in pkgs.writeShellApplication {
    name = "oss";

    runtimeInputs = with pkgs; [ coreutils curl jq util-linux ];

    text = builtins.replaceStrings
        [ "@agent@" "@aliasPairs@" "@aliasNames@" ]
        [ "${agent}/bin/oss-agent" pairs names ]
        (builtins.readFile ./oss.sh);
}
