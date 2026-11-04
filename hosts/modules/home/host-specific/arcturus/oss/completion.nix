{ pkgs, aliases } : let
    lib = pkgs.lib;

    names = lib.concatStringsSep " "
        (lib.unique (builtins.attrNames aliases ++ builtins.attrValues aliases));
in pkgs.writeTextFile {
    name = "oss-bash-completion";
    destination = "/share/bash-completion/completions/oss";
    text = builtins.replaceStrings [ "@models@" ] [ names ]
        (builtins.readFile ./completion.bash);
}
