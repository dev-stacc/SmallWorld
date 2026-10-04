{
    description = "Main flake";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        nixvim = {
            url = "github:nix-community/nixvim";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        claude-code = {
            url = "github:sadjow/claude-code-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        nixcord = {
            url = "github:FlameFlag/nixcord";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        sops-nix = {
            url = "github:Mic92/sops-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        nur = {
            url = "github:nix-community/NUR";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, ... } @ inputs :
    let
        inherit (nixpkgs) lib;

        username = "anastasia";
        tailnet = {
            domain = "tail789d60.ts.net";
            ips = {
                arcturus = "100.70.3.61";
                asta = "100.75.73.92";
                amateus = "100.70.98.107";
                aperture = "100.111.78.27";
                antinoos = "100.105.248.71";
                argus = "100.92.77.2";
                sanctuary = "100.113.161.17";
                alula = "100.104.236.122";
                atlas = "PLACEHOLDER";
            };
        };
        theme = import ./modules/theme;

        hosts = import ./hosts;

        inherit (import ./lib/mkHost.nix {
            inherit inputs lib username tailnet theme hosts;
        }) specialArgs mkSystem mkNode;

        byHostName = f: lib.mapAttrs' (name: host:
            lib.nameValuePair host.hostName (f name host)
        );
    in {
        nixosConfigurations = byHostName mkSystem hosts;

        colmena = {
            meta = {
                nixpkgs = nixpkgs.legacyPackages.x86_64-linux;
                inherit specialArgs;
            };
        } // byHostName mkNode (
            lib.filterAttrs (_: host: host.deploy or true) hosts
        );
    };
}
