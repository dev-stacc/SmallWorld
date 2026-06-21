{
    description = "Small World in a universe full of giants";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        stylix = {
            url = "github:danth/stylix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        hyprland = {
            url = "github:hyprwm/Hyprland";
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
        colmena = {
            url = "github:zhaofengli/colmena";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        sops-nix = {
            url = "github:Mic92/sops-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = {
        self,
        nixpkgs,
        home-manager,
        stylix,
        claude-code,
        nixcord,
        colmena,
        sops-nix,
        ...
    } @ inputs :
    let
        username = "anastasia";
        tailnet = {
            domain = "tail789d60.ts.net";
            ips = {
                arcturus = "100.70.3.61";
                asta = "100.88.255.118";
                amateus = "100.70.98.107";
                aperture = "100.111.78.27";
                antinoos = "100.103.107.52";
                argus = "100.92.77.2";
            };
        };
        specialArgs = { inherit inputs username tailnet; };
    in {
        nixosConfigurations = {
            Arcturus = nixpkgs.lib.nixosSystem {
                inherit specialArgs;
                modules = [ ./hosts/arcturus/default.nix ];
            };
            Amateus = nixpkgs.lib.nixosSystem {
                inherit specialArgs;
                modules = [ ./hosts/amateus/default.nix ];
            };
            Asta = nixpkgs.lib.nixosSystem {
                inherit specialArgs;
                modules = [ ./hosts/asta/default.nix ];
            };
            Antinoos = nixpkgs.lib.nixosSystem {
                inherit specialArgs;
                modules = [ ./hosts/antinoos/default.nix ];
            };
            Aperture = nixpkgs.lib.nixosSystem {
                inherit specialArgs;
                modules = [ ./hosts/aperture/default.nix ];
            };
            Argus = nixpkgs.lib.nixosSystem {
                inherit specialArgs;
                modules = [ ./hosts/argus/default.nix ];
            };
        };

        colmena = {
            meta = {
                nixpkgs = import nixpkgs { system = "x86_64-linux"; };
                inherit specialArgs;
            };
            Asta = { ... } : {
                imports = [
                    ./hosts/asta/default.nix
                    sops-nix.nixosModules.sops
                ];
                deployment= {
                    targetHost = "asta";
                    targetUser = username;
                };
            };
            Amateus = { ... } : {
                imports = [
                    ./hosts/amateus/default.nix
                    sops-nix.nixosModules.sops
                ];
                deployment = {
                    targetHost = "amateus";
                    targetUser = username;
                };
            };
            Antinoos = { ... } : {
                imports = [
                    ./hosts/antinoos/default.nix
                    sops-nix.nixosModules.sops
                ];
                deployment = {
                    targetHost = "antinoos";
                    targetUser = username;
                };
            };
            Aperture = { ... } : {
                imports = [
                    ./hosts/aperture/default.nix
                    sops-nix.nixosModules.sops
                ];
                deployment = {
                    targetHost = "aperture";
                    targetUser = username;
                };
            };
            Argus = { ... } : {
                imports = [
                    ./hosts/argus/default.nix
                    sops-nix.nixosModules.sops
                ];
                deployment = {
                    targetHost = "argus";
                    targetUser = username;
                };
            };
        };
    };
}
