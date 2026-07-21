# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [
    "usbcore.autosuspend=-1"
    "intel_idle.max_cstate=1"
    "irqpoll"
  ];
  boot.blacklistedKernelModules = [
    "axp20x_i2c"
    "axp288_charger"
    "axp288_fuel_gauge"
    "axp288_adc"
  ];
  
  hardware.enableRedistributableFirmware = true;

  networking.networkmanager.enable = true;
  networking.hostName = "Alula";

  users.users = {
    anastasia = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
    };
  };

  system.stateVersion = "25.11"; # Did you read the comment?

}

