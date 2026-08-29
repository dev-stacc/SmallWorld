{ username, tailnet, ... }: {
    programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
            AddKeysToAgent = "yes";
            "Host arcturus" = {
                Hostname = tailnet.ips.arcturus;
                User = username;
                IdentityFile = "~/.ssh/id_ed25519";
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
