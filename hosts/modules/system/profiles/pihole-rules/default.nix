{ config, lib, pkgs, ... } :
let
    cfg = config.biggerworld.piholeRules;
    rulesFile = pkgs.writeText "pihole-rules.json" (builtins.toJSON (import ./rules.nix));
in {
    options.biggerworld.piholeRules = {
        envFile = lib.mkOption {
            type = lib.types.str;
            description = ''
                File holding FTLCONF_webserver_api_password for the local Pi-hole.

                Each Pi-hole host already has one for its container, so point this
                at the same file: a sops template on aperture, the pre-boot
                provision file on argus. systemd reads EnvironmentFile as PID 1
                before dropping to the DynamicUser, so a root-owned 0400 or 0600
                file works.
            '';
        };

        onCalendar = lib.mkOption {
            type = lib.types.str;
            default = "*-*-* *:50:00";
            description = ''
                When to reconcile. Must land after both pihole-sync timers, which
                run at :00 (pull, argus -> aperture) and :30 (push, aperture ->
                argus), because the pull deletes anything aperture holds that
                argus does not. Seeding argus first means the next pull finds the
                full rule set there instead of wiping it, which is exactly how
                the 2026-11-09 rebuild lost 108 rules.
            '';
        };

        marker = lib.mkOption {
            type = lib.types.str;
            default = "biggerworld";
            readOnly = true;
            description = ''
                Comment written on every managed entry. It is also the ownership
                record: entries carrying it that are absent from rules.nix get
                deleted, and entries without it are left alone.
            '';
        };
    };

    config = {
        systemd.services.pihole-seed = {
            description = "Reconcile Pi-hole deny and allow entries from the flake";
            after = [ "podman-pihole.service" "sops-nix.service" ];
            wants = [ "podman-pihole.service" ];
            wantedBy = [ "multi-user.target" ];
            path = with pkgs; [ coreutils curl jq ];
            environment = {
                PIHOLE_URL = "http://127.0.0.1:8081";
                PIHOLE_RULES = "${rulesFile}";
                PIHOLE_MARKER = cfg.marker;
            };
            serviceConfig = {
                Type = "oneshot";
                ExecStart = "${pkgs.bash}/bin/bash ${./files/pihole-seed.sh}";
                EnvironmentFile = cfg.envFile;
                DynamicUser = true;
                NoNewPrivileges = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                PrivateTmp = true;
            };
        };

        systemd.timers.pihole-seed = {
            description = "Reconcile Pi-hole entries hourly";
            wantedBy = [ "timers.target" ];
            timerConfig = {
                OnCalendar = cfg.onCalendar;
                Persistent = true;
            };
        };
    };
}
