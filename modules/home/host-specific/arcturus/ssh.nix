{ ... }: {
    programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = {
            "*" = {
                extraOptions.AddKeysToAgent = "yes";
            };
            "arcturus" = {
                hostname = "100.70.3.61";
                user = "anastasia";
                identityFile = "~/.ssh/id_ed25519";
            };
        };
    };

    programs.bash = {
        enable = true;
        shellAliases = {
            smallworld = "eval $(ssh-agent) && ssh-add ~/.ssh/id_ed25519";
        };
    };
}
