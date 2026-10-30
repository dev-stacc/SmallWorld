{ pkgs } : let
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
        (pkgs.lib.mapAttrs' (n: ctx: pkgs.lib.nameValuePair "openai/${n}" (entry ctx))
            contexts));
in pkgs.writeShellApplication {
    name = "coder";

    runtimeInputs = with pkgs; [ aider-chat coreutils curl jq util-linux ];

    text = builtins.replaceStrings
        [ "@metadata@" ]
        [ "${metadata}" ]
        (builtins.readFile ./coder.sh);
}
