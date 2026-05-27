{ config, pkgs, ... } : {
    boot.initrd.kernelModules = ["amdgpu"];
    services.xserver.videoDrivers = ["amdGpu"];

    hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
            amdvlk
            rocmPackages.clr.icd
            libva
            libva-utils
            vaapiVdpau
        ];
        extraPackages32 = with pkgs.driversi686Linux; [
            amdvlk
        ];
    };

    environment.systemPackages = with pkgs; [
        radeontop
    ];
}
