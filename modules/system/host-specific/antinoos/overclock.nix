{ config, pkgs, ... } : {
    hardware.amdgpu.overdrive = { 
        enable = true;
        ppfeaturemask = "0xffffffff";
    };

    programs.corectrl.enable = true;
}
