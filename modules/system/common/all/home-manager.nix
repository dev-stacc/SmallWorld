{ pkgs, config, inputs, username, tailnet, ...} : {
    imports = [
        inputs.home-manager.nixosModules.home-manager
    ];

    home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        extraSpecialArgs = {
            inherit inputs username tailnet;
            fontName = config.stylix.fonts.monospace.name;
            fontSize = config.stylix.fonts.sizes.terminal;
        };
    };
}
