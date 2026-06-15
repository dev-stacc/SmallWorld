{ username, tailnet, ... }: {
    programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = {
            "*" = {
                extraOptions.AddKeysToAgent = "yes";
            };
            "arcturus" = {
                hostname = tailnet.ips.arcturus;
                user = username;
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
