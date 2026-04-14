{ config, pkgs, ... } : {

 nix.settings.experimental-features = ["nix-command" "flakes"];
 system.stateVersion = "25.11";
 time.timeZone = "America/New_York";
 hardware.graphics.enable = true;

 boot = {
  loader.systemd-boot.enable = true;
  loader.efi.canTouchEfiVariables = true;
 };

 users.users.anastasia = {
  isNormalUser = true;
  extraGroups = [
   "wheel"
   "networkmanager"
   "video"
   "input"
   "audio"
  ];
 };

}
