{ pkgs } : pkgs.writers.writePython3Bin "oss-agent" {
    libraries = [ ];
    flakeIgnore = [ "E501" ];
} (builtins.replaceStrings
    [ "@bwrap@" "@cat@" "@ls@" "@rg@" "@journalctl@" "@kubectl@" "@git@" ]
    [
        "${pkgs.bubblewrap}/bin/bwrap"
        "${pkgs.coreutils}/bin/cat"
        "${pkgs.coreutils}/bin/ls"
        "${pkgs.ripgrep}/bin/rg"
        "${pkgs.systemd}/bin/journalctl"
        "${pkgs.kubectl}/bin/kubectl"
        "${pkgs.git}/bin/git"
    ]
    (builtins.readFile ./agent.py))
