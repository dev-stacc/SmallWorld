{ ... } : {
    home-manager.users.anastasia = {
        imports = [
            ../../modules/home/arcturus.nix
        ];
        home.username = "anastasia";
        home.homeDirectory = "/home/anastasia";
        home.stateVersion = "25.11";

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

        sops.age.keyFile = "~/.sops/keys.txt";
    };
}
