{ ... } : {
    programs.bash = {
        enable = true;
        shellAliases = {
            smallworld = "eval $(ssh-agent) && ssh-add ~/.ssh/id_ed25519";
        };
    };
}
