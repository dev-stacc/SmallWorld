{ pkgs } : pkgs.writers.writePython3Bin "oss-agent" {
    libraries = [ ];
    flakeIgnore = [ "E501" ];
} (builtins.replaceStrings
    [ "@bwrap@" "@cat@" "@ls@" "@rg@" "@journalctl@" "@kubectl@" "@git@" "@run0@" "@true@" ]
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
    ]
    (builtins.readFile ./agent.py))
