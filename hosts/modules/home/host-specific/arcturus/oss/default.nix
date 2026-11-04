{ pkgs, ... } : let
    aliases = {
        default = "gpt-oss-20b-uncensored";
        gpt = "gpt-oss-20b-uncensored";
        coder = "qwen3-coder";
        fast = "qwen3-coder-fast";
        qwen = "qwen3.6-uncensored";
        overnight = "qwen3-coder-max";
    };

    agent = import ./agent.nix { inherit pkgs aliases; };

    oss = import ./oss.nix { inherit pkgs agent aliases; };

    completion = import ./completion.nix { inherit pkgs aliases; };
in {
    home.packages = [ oss completion ];
}
