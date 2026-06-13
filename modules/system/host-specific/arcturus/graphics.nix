{ config, pkgs, ... } : {
    services.xserver.videoDrivers = [ "modesetting" ];

    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

    hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
            intel-media-driver
            libva
            libva-utils
            vpl-gpu-rt
        ];
    };

    environment.systemPackages = with pkgs; [
        intel-gpu-tools
    ];

}
