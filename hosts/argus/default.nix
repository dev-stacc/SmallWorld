{ ... } : {
    imports = [
        ./home.nix
        ./hardware-configuration.nix
        ../../modules/system/host-specific/argus/default.nix
    ];
}
