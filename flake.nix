{
    description = "Arcturus config";
    
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
        hyprland.url = "github:hyprwm/Hyprland";
    };
    
    outputs = { self, nixpkgs, home-manager, stylix, ... } @ inputs : {
        nixosConfigurations.Arcturus = nixpkgs.lib.nixosSystem {
            specialArgs = { inherit inputs; };
            modules = [ ./modules/default.nix ];
        };
    };
}