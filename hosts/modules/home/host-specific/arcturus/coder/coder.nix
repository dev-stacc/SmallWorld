{ pkgs, theme } : let
    lib = pkgs.lib;

    colors = theme.base16;

    pyStyleName = "pygarnment";
    pyStyleClass = "Pygarnment";
    codeTheme = pyStyleName;

    baseNames = [
        "base00" "base01" "base02" "base03"
        "base04" "base05" "base06" "base07"
        "base08" "base09" "base0A" "base0B"
        "base0C" "base0D" "base0E" "base0F"
    ];

    basePlaceholders = map (n: "@${n}@") baseNames;
    baseValues = map (n: colors.${n}) baseNames;

    contexts = {
        "qwen3-coder" = 32768;
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

    themedPyStyle = pkgs.writeTextFile {
        name = "${pyStyleName}.py";
        text = builtins.replaceStrings basePlaceholders baseValues
            (builtins.readFile ./colors/pygarnment.py);
    };

    themedSitecustomize = pkgs.writeTextFile {
        name = "sitecustomize.py";
        text = builtins.replaceStrings basePlaceholders baseValues
            (builtins.readFile ./colors/sitecustomize.py);
    };

    pyStylePlugin = pkgs.runCommand "${pyStyleName}-pygments-plugin" { } ''
        mkdir -p "$out/${pyStyleName}-1.0.0.dist-info"
        cp ${themedPyStyle} "$out/${pyStyleName}.py"
        cp ${themedSitecustomize} "$out/sitecustomize.py"

        cat > "$out/${pyStyleName}-1.0.0.dist-info/METADATA" <<EOF
        Metadata-Version: 2.1
        Name: ${pyStyleName}
        Version: 1.0.0
        EOF

        cat > "$out/${pyStyleName}-1.0.0.dist-info/entry_points.txt" <<EOF
        [pygments.styles]
        ${pyStyleName} = ${pyStyleName}:${pyStyleClass}
        EOF
    '';
in pkgs.writeShellApplication {
    name = "coder";

    runtimeInputs = with pkgs; [ aider-chat coreutils curl jq util-linux ];

    text = builtins.replaceStrings
        ([
            "@metadata@"
            "@settings@"
            "@codeTheme@"
            "@pyStylePath@"
        ] ++ basePlaceholders)
        ([
            "${metadata}"
            "${settings}"
            codeTheme
            "${pyStylePlugin}"
        ] ++ baseValues)
        (builtins.readFile ./coder.sh);
}
