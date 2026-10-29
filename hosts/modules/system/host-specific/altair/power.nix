{ ... } : {
    networking.interfaces.enp3s0.wakeOnLan.enable = true;

    services.udev.extraRules = ''
        ACTION=="add|bind", SUBSYSTEM=="pci", DRIVERS=="amdgpu", ATTR{vendor}=="0x1002", ATTR{power/autosuspend_delay_ms}="3600000"
    '';
}
