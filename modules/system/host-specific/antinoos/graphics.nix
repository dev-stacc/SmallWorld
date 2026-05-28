{ config, pkgs, ... } : {
    boot.initrd.kernelModules = [ "amdgpu" ];
    services.xserver.videoDrivers = [ "amdgpu" ];

    hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
            rocmPackages.clr.icd
            libva
            libva-utils
            libva-vdpau-driver
        ];
    };

    environment.systemPackages = with pkgs; [
        radeontop
    ];
}
