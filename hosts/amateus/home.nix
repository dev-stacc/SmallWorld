{ ... } : {
    home-manager.users.anastasia = {
        imports = [
            ../../modules/home/amateus.nix
        ];
        home.username = "anastasia";
        home.homeDirectory = "/home/anastasia";
        home.stateVersion = "25.11";
    };
}
