{ pkgs, ... }: {
    boot.initrd.kernelModules = [ "amdgpu" ];
    services.xserver.videoDrivers = [ "amdgpu" ];

    environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "radeonsi";
    };

    hardware = {
        graphics = {
            enable = true;
            enable32Bit = true;
            extraPackages = with pkgs; [
                rocmPackages.clr.icd
                libva
                libva-utils
                libva-vdpau-driver
            ];
        };
    };

    environment.systemPackages = with pkgs; [
        radeontop
    ];
}
