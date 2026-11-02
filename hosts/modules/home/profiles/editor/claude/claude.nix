{ pkgs } : pkgs.symlinkJoin {
    name = "claude-code-trimmed";

    paths = [ pkgs.claude-code ];

    nativeBuildInputs = [ pkgs.makeWrapper ];

    postBuild = ''
        wrapProgram $out/bin/claude \
            --add-flags "--tools Bash,Read,Write,Edit,Agent,AskUserQuestion,ToolSearch" \
            --add-flags "--strict-mcp-config"
    '';
}
