{ ... } : {
    networking.interfaces.enp5s0.wakeOnLan.enable = true;

    services.udev.extraRules = ''
        ACTION=="add|bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x1002", ATTR{class}=="0x030000", ATTR{power/autosuspend_delay_ms}="600000"
    '';
}
