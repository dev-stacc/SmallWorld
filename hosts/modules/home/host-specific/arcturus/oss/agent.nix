{ pkgs, aliases } : let
    lib = pkgs.lib;

    literal = "{" + lib.concatStringsSep ", " (lib.mapAttrsToList
        (name: target: "\"${name}\": \"${target}\"") aliases) + "}";
in pkgs.writers.writePython3Bin "oss-agent" {
    libraries = [ ];
    flakeIgnore = [ "E501" ];
} (builtins.replaceStrings
    [
        "@bwrap@" "@cat@" "@ls@" "@rg@" "@journalctl@" "@kubectl@" "@git@"
        "@run0@" "@true@" "@fd@" "@nixparse@" "@shellcheck@" "@yq@" "@jqbin@"
        "@aliases@"
    ]
    [
        "${pkgs.bubblewrap}/bin/bwrap"
        "${pkgs.coreutils}/bin/cat"
        "${pkgs.coreutils}/bin/ls"
        "${pkgs.ripgrep}/bin/rg"
        "${pkgs.systemd}/bin/journalctl"
        "${pkgs.kubectl}/bin/kubectl"
        "${pkgs.git}/bin/git"
        "${pkgs.systemd}/bin/run0"
        "${pkgs.coreutils}/bin/true"
        "${pkgs.fd}/bin/fd"
        "${pkgs.nix}/bin/nix-instantiate"
        "${pkgs.shellcheck}/bin/shellcheck"
        "${pkgs.yq-go}/bin/yq"
        "${pkgs.jq}/bin/jq"
        literal
    ]
    (builtins.readFile ./agent.py))
