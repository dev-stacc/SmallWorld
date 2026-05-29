{ config, pkgs, ... } : {
    programs.corectrl = {
        enable = true;
    };
    hardware.amdgpu.overdrive = { 
        gpuOverclock.enable = true;
        gpuOverclock.ppfeaturemask = "0xffffffff";
    };
}
