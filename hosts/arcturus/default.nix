{ ... } : {
    imports = [
        ./home.nix
        ./hardware-configuration.nix
        ../../modules/system/host-specific/arcturus/default.nix
    ];
}
