{ inputs, username, tailnet, theme, ...} : {
    imports = [
        inputs.home-manager.nixosModules.home-manager
    ];

    home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        extraSpecialArgs = {
            inherit inputs username tailnet theme;
        };
    };
}
