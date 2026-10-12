{ config, lib, pkgs, tailnet, ... } :
let
    cfg = config.biggerworld.ups;

    notify = config.biggerworld.notify.command;
    selfIp = tailnet.ips.${lib.toLower config.networking.hostName};

    secretsFile = ../../../../../secrets/secrets.yaml;
    passwordFile = config.sops.secrets.nut-upsmon-password.path;

    notifier = pkgs.writeShellScript "upsmon-ntfy" ''
        set -eu

        message="''${1:-''${NOTIFYTYPE:-ups event}}"
        summary="$(${pkgs.inetutils}/bin/hostname) ups: $message"

        ${pkgs.util-linux}/bin/logger -t upsmon "$summary"

        if [ -n "${notify}" ]; then
            NOTIFY_PRIORITY=urgent ${notify} "$summary" || true
        fi
    '';

    events = [
        [ "ONBATT" "SYSLOG+EXEC" ]
        [ "ONLINE" "SYSLOG+EXEC" ]
        [ "LOWBATT" "SYSLOG+EXEC" ]
        [ "FSD" "SYSLOG+EXEC" ]
        [ "COMMBAD" "SYSLOG+EXEC" ]
        [ "COMMOK" "SYSLOG+EXEC" ]
        [ "SHUTDOWN" "SYSLOG+EXEC" ]
        [ "REPLBATT" "SYSLOG+EXEC" ]
        [ "NOCOMM" "SYSLOG+EXEC" ]
    ];

    shared = {
        NOTIFYCMD = "${notifier}";
        NOTIFYFLAG = events;
        SHUTDOWNCMD = "${pkgs.systemd}/bin/systemctl poweroff";
        MINSUPPLIES = 1;
        POLLFREQ = 5;
        POLLFREQALERT = 5;
        DEADTIME = 15;
    };
in {
    options.biggerworld.ups = {
        role = lib.mkOption {
            type = lib.types.enum [ "none" "master" "slave" ];
            default = "none";
            description = ''
                This host's place in the NUT topology.

                "none" leaves NUT entirely unconfigured, which is the state
                every host ships in until a UPS is physically wired up. "master"
                is the one host holding the UPS data cable: it runs the driver,
                upsd and upsmon. "slave" runs upsmon only and takes its cue from
                the master over the tailnet.
            '';
        };

        driver = lib.mkOption {
            type = lib.types.str;
            default = "usbhid-ups";
            description = ''
                NUT driver for the attached UPS, for role "master".

                Run `nut-scanner -U` on the host to find the right value; most
                USB consumer units want usbhid-ups.
            '';
        };

        port = lib.mkOption {
            type = lib.types.str;
            default = "auto";
            description = ''
                Device port for the attached UPS, for role "master".
                "auto" is correct for USB; serial units need a /dev path.
            '';
        };

        master = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = ''
                Lowercase host name of the UPS master, for role "slave".
                Resolved to a tailnet IP, so upsmon never depends on DNS.
            '';
        };

        name = lib.mkOption {
            type = lib.types.str;
            default = "main";
            description = "UPS identifier shared by upsd and every upsmon.";
        };
    };

    config = lib.mkMerge [
        (lib.mkIf (cfg.role != "none") {
            sops.secrets.nut-upsmon-password = {
                sopsFile = secretsFile;
                owner = config.power.ups.upsmon.user;
                mode = "0400";
            };
        })

        (lib.mkIf (cfg.role == "master") {
            power.ups = {
                enable = true;
                mode = "netserver";

                ups.${cfg.name} = {
                    driver = cfg.driver;
                    port = cfg.port;
                    description = "fleet ups";
                };

                users.upsmon = {
                    inherit passwordFile;
                    upsmon = "primary";
                };

                upsd.listen = [
                    { address = "127.0.0.1"; }
                    { address = selfIp; }
                ];

                upsmon = {
                    monitor.${cfg.name} = {
                        system = cfg.name;
                        user = "upsmon";
                        type = "primary";
                    };
                    settings = shared;
                };
            };

            networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 3493 ];
        })

        (lib.mkIf (cfg.role == "slave") {
            assertions = [{
                assertion = cfg.master != "";
                message =
                    "biggerworld.ups.role is \"slave\" but no master host is set";
            }];

            power.ups = {
                enable = true;
                mode = "netclient";

                upsmon = {
                    monitor.${cfg.name} = {
                        system = "${cfg.name}@${tailnet.ips.${cfg.master}}";
                        user = "upsmon";
                        inherit passwordFile;
                        type = "secondary";
                    };
                    settings = shared;
                };
            };
        })
    ];
}
