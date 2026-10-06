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
                # Not a host: the CrowdSec LAPI, exposed on the tailnet by the
                # tailscale operator via k8s/apps/crowdsec/service.yaml. Hosts
                # reach it by IP rather than MagicDNS name because argus runs
                # its own resolver with services.resolved disabled.
                crowdsec = "100.127.104.71";
                # Likewise Loki, exposed by k8s/apps/monitoring/loki-service.yaml
                # so albireo's host-level Alloy can push to it. Fill this in once
                # the LoadBalancer has been assigned its address - albireo's
                # log-shipping.nix stays off while it reads PLACEHOLDER.
                loki = "PLACEHOLDER";
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
