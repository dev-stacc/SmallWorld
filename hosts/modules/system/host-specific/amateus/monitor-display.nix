{ config, pkgs, tailnet, theme, ... } :
let
    secretsFile = ../../../../../secrets/secrets.yaml;
    port = 9847;

    palette = with theme.base16; [
        base00
        base02
        base06
        base04
        base03
        base02
        base03
        base05
        base00
        base02
        base06
        base04
        base03
        base02
        base03
        base05
    ];
in {
    sops = {
        secrets = {
            ntfy-topic.sopsFile = secretsFile;
            ntfy-token.sopsFile = secretsFile;
        };

        templates."monitor-display.env".content = ''
            NTFY_TOPIC=${config.sops.placeholder.ntfy-topic}
            NTFY_TOKEN=${config.sops.placeholder.ntfy-token}
        '';
    };

    console.colors = palette;

    boot.kernelParams = [ "consoleblank=0" ];

    systemd.services."getty@tty1".enable = false;

    systemd.services.monitor-display = {
        description = "Fleet monitor console display";
        after = [ "network-online.target" "sops-nix.service" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        conflicts = [ "getty@tty1.service" ];

        environment = {
            TERM = "linux";
            LANG = config.i18n.defaultLocale;
            LOCALE_ARCHIVE = "/run/current-system/sw/lib/locale/locale-archive";
            DISPLAY_STATE_URL =
                "http://${tailnet.ips.algol}:${toString port}/state.json";
            DISPLAY_FETCH_INTERVAL = "15";
            DISPLAY_STALE_AFTER = "90";
            DISPLAY_DEAD_AFTER = "300";
            DISPLAY_DEEP_LINK = "https://grafana.${tailnet.domain}/";
        };

        serviceConfig = {
            ExecStartPre =
                "-${pkgs.util-linux}/bin/setterm --blank 0 --powersave off";
            ExecStart = "${pkgs.python3}/bin/python3 ${./files/monitor-display.py}";
            EnvironmentFile = config.sops.templates."monitor-display.env".path;
            StandardInput = "tty";
            StandardOutput = "tty";
            StandardError = "journal";
            TTYPath = "/dev/tty1";
            TTYReset = true;
            TTYVHangup = true;
            TTYVTDisallocate = true;
            Restart = "always";
            RestartSec = 5;
        };
    };
}
