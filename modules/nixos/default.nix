{ config, pkgs, ... } : {

 imports = [
  ./base.nix
  ./hardware-configuration.nix
  ./networking.nix
  ./bluetooth.nix
  ./sound.nix
 ];
}
