{ config, pkgs, ... } : {
    hardware.amdgpu.overdrive = { 
        gpuOverclock.enable = true;
        gpuOverclock.ppfeaturemask = "0xffffffff";
    };
}
