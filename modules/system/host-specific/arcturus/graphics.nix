{ config, pkgs, ... } : {
    services.xserver.videoDrivers = [ "modesetting" ];

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
