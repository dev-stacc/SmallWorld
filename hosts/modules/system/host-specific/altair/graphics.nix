{ pkgs, ... } : {
    hardware.amdgpu.initrd.enable = true;

    hardware.graphics.enable = true;

    environment.systemPackages = with pkgs; [
        radeontop
        vulkan-tools
    ];
}
