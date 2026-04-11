{pkgs, config, ...} :
let
 palette = import ./theme/palette.nix;
in
{
 imports = [
  ./theme/hyprland.nix
  ./theme/kitty.nix
  ./theme/waybar.nix
  ./programs.nix
 ];
  
 home.username = "anastasia";
 home.homeDirectory = "/home/anastasia";
 home.stateVersion = "25.11";

}
