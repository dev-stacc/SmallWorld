{ pkgs, config, inputs, ...} : {
    imports = [
        inputs.home-manager.nixosModules.home-manager
    ];

    home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        extraSpecialArgs = {
            inherit inputs;
            fontName = config.stylix.fonts.monospace.name;
            fontSize = config.stylix.fonts.sizes.terminal;
        };
    }; 
}
