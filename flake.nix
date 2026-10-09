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
                argus = "100.92.77.2";
                sanctuary = "100.113.161.17";
                alula = "100.104.236.122";
                atlas = "PLACEHOLDER";
                albireo = "100.114.197.75";
                altair = "100.116.223.58";
                algol = "100.79.222.127";

                # k8s services exposed by the tailscale operator, not hosts
                crowdsec = "100.127.104.71";
                loki = "100.126.37.99";
            };
        };
        theme = import ./hosts/modules/theme;

        hosts = import ./hosts;

        inherit (import ./hosts/mkHost.nix {
            inherit inputs lib username tailnet theme hosts;
        }) specialArgs mkSystem mkNode;

        byHostName = f: lib.mapAttrs' (name: host:
            lib.nameValuePair host.hostName (f name host)
        );
    in {
        inherit tailnet;

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
