{ ... } : {
    home-manager.users.anastasia = {
        imports = [
            ../../modules/home/asta.nix
        ];
        home.username = "anastasia";
        home.homeDirectory = "/home/anastasia";
        home.stateVersion = "25.11";
        home.sessionVariables = {
            SOPS_AGE_KEY_FILE = "/home/anastasia/.sops/keys.txt";
        };
    };
}
