{ pkgs, theme } : let
    lib = pkgs.lib;

    colors = theme.base16;

    codeTheme = "ansi_dark";

    contexts = {
        "qwen3-coder" = 24576;
        "qwen3-coder-fast" = 32768;
        "gpt-oss-20b-uncensored" = 32768;
        "qwen3.6-uncensored" = 32768;
    };

    reserved = 4096;

    entry = ctx: {
        max_input_tokens = ctx - reserved;
        max_output_tokens = reserved;
        max_tokens = ctx;
        input_cost_per_token = 0;
        output_cost_per_token = 0;
        litellm_provider = "openai";
        mode = "chat";
        supports_function_calling = true;
    };

    metadata = pkgs.writeText "aider-model-metadata.json" (builtins.toJSON
        (lib.mapAttrs' (n: ctx: lib.nameValuePair "openai/${n}" (entry ctx))
            contexts));

    settings = pkgs.writeText "aider-model-settings.json" (builtins.toJSON
        (lib.mapAttrsToList (n: _: {
            name = "openai/${n}";
            edit_format = "whole";
            editor_edit_format = "editor-whole";
            use_repo_map = true;
        }) contexts));
in pkgs.writeShellApplication {
    name = "coder";

    runtimeInputs = with pkgs; [ aider-chat coreutils curl jq util-linux ];

    text = builtins.replaceStrings
        [
            "@metadata@"
            "@settings@"
            "@codeTheme@"
            "@base00@"
            "@base07@"
            "@base02@"
            "@base03@"
            "@base04@"
            "@base05@"
            "@base06@"
        ]
        [
            "${metadata}"
            "${settings}"
            codeTheme
            colors.base00
            colors.base07
            colors.base02
            colors.base03
            colors.base04
            colors.base05
            colors.base06
        ]
        (builtins.readFile ./coder.sh);
}
