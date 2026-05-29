{ config, pkgs, ... } : {
    boot.initrd.kernelModules = [ "amdgpu" ];
    services.xserver.videoDrivers = [ "amdgpu" ];

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
        amdgpu.overdrive = { 
            enable = true;
            ppfeaturemask = "0xffffffff";
        };
    };

    programs.corectrl.enable = true;
    
    environment.systemPackages = with pkgs; [
        radeontop
    ];

    systemd.user.services.corectrl = {
        description = "corectrl gpu settings";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
            ExecStart = "${pkgs.corectrl}/bin/corectrl --minimize-systray";
            Restart = "on-failiure";
        };
    };
}
