{ config, lib, pkgs, inputs, ... }:

{
 nix.settings.experimental-features = ["nix-command" "flakes"];
 system.stateVersion = "25.11";
 imports = [
  ./hardware-configuration.nix
  ./theme/stylix.nix
 ];

 time.timeZone = "America/New_York";

 hardware = {
  alsa.enablePersistence = true;
  graphics.enable = true;
  bluetooth = {
   enable = true;
   powerOnBoot = false;
   settings = {
    General = {
     ControllerMode = "dual";
     FastConnectable = "true";
     Experimental = "true";
    };
    Policy = {AutoEnable = "false";};
   };
  };
 };

 boot = {
  loader.systemd-boot.enable = true;
  loader.efi.canTouchEfiVariables = true;
  kernelModules = [
   "btusb"
   "bluetooth"
  ];
 };

 networking = {
  hostName = "Arcturus"; 
  wireless.iwd = {
   enable = true;
   settings = {
    Network = {
     EnableIPv6 = true;
    };
    Settings = {
     AutoConnect = true;
    };
   };
  };
  firewall = {
   enable = true;
   trustedInterfaces = ["tailscale0"];
  };
 };

 services = {
  tailscale.enable = true;
  openssh = {
   enable = true;
   settings.PasswordAuthentication = false;
   settings.PermitRootLogin = "no";
  };
  pipewire = {
   enable = true;
   alsa.enable = true;
   alsa.support32Bit = true;
   pulse.enable = true;
   jack.enable = true;
  };
 };
 
 systemd.user.services.kanshi = {
  description = "kanshi daemon";
  serviceConfig = {
   Type = "simple";
   ExecStart = ''${pkgs.kanshi}/bin/kanshi -C kanshi_config_file'';
  };
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

 security = {
  rtkit.enable = true;
  sudo.extraRules = [
   {
    users = ["anastasia"];
    commands = [
     {
      command = "${pkgs.tailscale}/bin/tailscale";
      options = ["NOPASSWD"];}
    ];
   }
  ];
 };

 xdg.portal = {
  enable = true;
  config.common.default = "*";
  extraPortals = [
   pkgs.xdg-desktop-portal-hyprland
   pkgs.xdg-desktop-portal-gtk
  ];
 };

 programs = {
  dconf.enable = true;
  hyprland = {
   enable = true;
   xwayland.enable = true;
  };
 };

 environment = {
  sessionVariables = {
   WLR_NO_HARDWARE_CURORS = "1";
   NIXOS_OZONE_WL = "1";
  };
  systemPackages = [
   pkgs.vim
   pkgs.kitty
   pkgs.waybar
   pkgs.git
   pkgs.fzf
   pkgs.brightnessctl
   pkgs.bluez
   pkgs.fresh-editor
   pkgs.vesktop
   pkgs.libnotify
   pkgs.mako
   pkgs.hyprshot
  ];
 };
}

