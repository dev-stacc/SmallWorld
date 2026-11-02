{ pkgs } : pkgs.runCommand "claude-code-full" { } ''
    mkdir -p $out/bin
    ln -s ${pkgs.claude-code}/bin/claude $out/bin/claude-full
''
