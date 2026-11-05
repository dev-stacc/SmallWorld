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

    users.groups.trackball = { };

    users.users.trackball = {
        isSystemUser = true;
        group = "trackball";
        description = "trackball scroll mode";
    };

    systemd.services.trackball-scroll = {
        description = "Scroll Lock toggles trackball scroll mode";
        wantedBy = [ "multi-user.target" ];

        unitConfig.StartLimitIntervalSec = 0;

        serviceConfig = {
            Type = "simple";
            ExecStartPre = "+${pkgs.acl}/bin/setfacl -m u:trackball:rw /dev/uinput";
            ExecStart = "${runner}/bin/trackball-scroll";
            Restart = "always";
            RestartSec = 5;

            User = "trackball";
            SupplementaryGroups = [ "input" "uinput" ];

            PrivateNetwork = true;
            RestrictAddressFamilies = [ "AF_UNIX" ];
            IPAddressDeny = "any";

            ProtectHome = true;
            ProtectSystem = "strict";
            PrivateTmp = true;
            ProtectProc = "invisible";
            ProcSubset = "pid";

            DevicePolicy = "closed";
            DeviceAllow = [ "char-input rw" "/dev/uinput rw" ];

            CapabilityBoundingSet = "";
            NoNewPrivileges = true;
            RestrictNamespaces = true;
            RestrictSUIDSGID = true;
            RestrictRealtime = true;
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            RemoveIPC = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectKernelLogs = true;
            ProtectClock = true;
            ProtectControlGroups = true;
            SystemCallFilter = [ "@system-service" ];
            SystemCallArchitectures = "native";
            UMask = "0077";
        };
    };
}
