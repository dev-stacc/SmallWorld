{ ... } : {
    imports = [
        ./home.nix
        ./hardware-configuration.nix
        ../../modules/system/host-specific/atlas/default.nix
    ];
}
