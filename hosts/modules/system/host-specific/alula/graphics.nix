{ pkgs, ... }: {
    services.xserver.videoDrivers = [ "modesetting" ];

    environment.sessionVariables.LIBVA_DRIVER_NAME = "i965";

    hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
            libva
            intel-vaapi-driver
        ];
    };
}
