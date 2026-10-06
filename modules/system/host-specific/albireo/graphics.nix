# E3-1220v2 has no iGPU and this board has no IPMI, so the RX580 is the only
# route to a BIOS screen. It does no transcoding.
{ ... } : {
    boot.initrd.kernelModules = [ "amdgpu" ];
    hardware.graphics.enable = true;
}
