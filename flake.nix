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
    };
    
    outputs = {
        self,
        nixpkgs,
        home-manager,
        stylix,
        claude-code,
        nixcord,
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
    };
}
