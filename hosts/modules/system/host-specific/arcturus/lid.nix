{ ... } : {
    # All three are required: HandleLidSwitchDocked defaults to "ignore", and logind
    # counts >1 connected display as docked.
    services.logind.settings.Login = {
        HandleLidSwitch = "poweroff";
        HandleLidSwitchExternalPower = "poweroff";
        HandleLidSwitchDocked = "poweroff";
    };
}
