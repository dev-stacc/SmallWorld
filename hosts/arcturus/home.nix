{ ... } : {
    home-manager.users.anastasia = {
        imports = [
            ../../modules/home/arcturus.nix
        ];
        home.username = "anastasia";
        home.homeDirectory = "/home/anastasia";
        home.stateVersion = "25.11";
        home.sessionVariables = {
            SOPS_AGE_KEY_FILE = "/home/anastasia/.sops/keys.txt";
        };

        programs.ssh = {
            enable = true;
            extraConfig = "AddKeysToAgent yes";
            matchBlocks = {
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
    };
}
