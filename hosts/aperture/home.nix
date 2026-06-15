{ username, ... } : {
    home-manager.users.${username} = {
        imports = [
            ../../modules/home/host-specific/aperture/default.nix
        ];
        home.username = username;
        home.homeDirectory = "/home/${username}";
        home.stateVersion = "25.11";
        home.sessionVariables = {
            SOPS_AGE_KEY_FILE = "/home/${username}/.sops/keys.txt";
        };
    };
}
