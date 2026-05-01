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
        kubenix = {
            url = "github:hall/kubenix";
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
        kubenix,
        ...
    } @ inputs : {
        nixosConfigurations = {
            Arcturus = nixpkgs.lib.nixosSystem {
                specialArgs = { inherit inputs; };
                modules = [ ./hosts/arcturus/default.nix ];
            };
            Amateus = nixpkgs.lib.nixosSystem {
                specialArgs = { inherit inputs; };
                modules = [ ./hosts/amateus/default.nix ];
	          };
            Asta = nixpkgs.lib.nixosSystem {
                specialArgs = { inherit inputs; };
                modules = [ ./hosts/asta/default.nix ];
	          };
        };

        colmena = {
            meta = {
                nixpkgs = import nixpkgs { system = "x86_64-linux"; };
                specialArgs = { inherit inputs; };
            };
            Asta = { ... } : {
                imports = [
                    ./hosts/asta/default.nix 
                    sops-nix.nixosModules.sops
                ];
                deployment= {
                    targetHost = "asta";
                    targetUser = "anastasia";
                };
            };
            Amateus = { ... } : {
                imports = [
                    ./hosts/amateus/default.nix 
                    sops-nix.nixosModules.sops
                ];
                deployment = {
                    targetHost = "amateus";
                    targetUser = "anastasia";
                };
            };
        };

        kubenix = {
            tailscale-operator = kubenix.evalModules.x86_64-linux {
                module = ./apps/tailscale-operator.nix;
            };
            sops-operator = kubenix.evalModules.x86_64-linux {
                module = ./apps/sops-operator.nix;
            };
        };
    };
}
