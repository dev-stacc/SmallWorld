{ pkgs, ... } : let
    keyboard = "/dev/input/by-id/usb-04d9_a0be-event-kbd";
    trackball = "/dev/input/by-id/usb-04d9_a0be-if01-event-mouse";

    speed = 15;

    runner = pkgs.writeShellApplication {
        name = "trackball-scroll";

        runtimeInputs = with pkgs; [ evsieve ];

        text = ''
            exec evsieve \
                --input ${keyboard} domain=kbd persist=reopen \
                --input ${trackball} domain=ball grab persist=reopen \
                --hook key:scrolllock@kbd toggle \
                --block @kbd \
                --toggle rel:y@ball rel:y rel:wheel_hi_res:-${toString speed}x \
                --toggle rel:x@ball rel:x rel:x:0x \
                --output name=trackball
        '';
    };
in {
    hardware.uinput.enable = true;

    systemd.services.trackball-scroll = {
        description = "Scroll Lock toggles trackball scroll mode";
        wantedBy = [ "multi-user.target" ];

        unitConfig.StartLimitIntervalSec = 0;

        serviceConfig = {
            Type = "simple";
            ExecStart = "${runner}/bin/trackball-scroll";
            Restart = "always";
            RestartSec = 5;
        };
    };
}
