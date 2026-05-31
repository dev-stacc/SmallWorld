{ config, pkgs, ... } : {
    services = {
        udev.extraRules = ''
            KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
        '';
        sunshine = {
            enable = true;
            autoStart = true;
            capSysAdmin = true;
            openFirewall = true;
            settings = {
                sunshine_name = "morning-star";
                encoder = "vaapi";
                adapter_name = "/dev/dri/renderD128";
                min_log_level = "info";
            };
        };
    };

    boot.kernelModules = [ "uinput" ];
}
