{ config, pkgs, ... } : {
    hardware.amdgpu.overdrive = { 
        enable = true;
        ppfeaturemask = "0xffffffff";
    };
}
