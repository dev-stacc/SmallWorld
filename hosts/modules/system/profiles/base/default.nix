{ ... } : {
    imports= [
        ./base.nix
        ./home-manager.nix
        ./networking.nix
        ./tailscale-serve.nix
        ./packages.nix
        ./users.nix
    ];
}
