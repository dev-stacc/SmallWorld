{ ... } : {
    imports = [
        ./home.nix
        ./hardware-configuration.nix
        ../../modules/system/host-specific/asta/default.nix
    ];
}
