{ config, lib, pkgs, ... } :
let
    haveSecrets = config.biggerworld.secrets.enable;
    notify = config.biggerworld.notify.command;

    mailer = pkgs.writeShellScript "smartd-ntfy" ''
        set -eu

        message="$(cat)"
        subject="$(printf '%s\n' "$message" \
            | ${pkgs.gnused}/bin/sed -n 's/^Subject: *//p' \
            | head -1)"
        detail="$(printf '%s\n' "$message" \
            | ${pkgs.gawk}/bin/awk 'f && /^smartctl [0-9]/ {exit} f && NF {print} /^$/ {f=1}' \
            | head -3 \
            | cut -c1-160)"

        summary="''${subject:-smartd alert}"
        if [ -n "$detail" ]; then
            summary="$summary
        $detail"
        fi

        if [ -n "${notify}" ]; then
            NOTIFY_PRIORITY=urgent ${notify} "$summary"
        else
            printf '%s\n' "$summary" | ${pkgs.util-linux}/bin/wall 2>/dev/null || true
        fi
    '';
in {
    services.smartd = {
        enable = true;
        autodetect = true;

        defaults.monitored = "-a -o on -S on -s (S/../.././02|L/../../6/01)";

        notifications = {
            wall.enable = !haveSecrets;
            mail = lib.mkIf haveSecrets {
                enable = true;
                sender = "smartd";
                recipient = "fleet";
                mailer = "${mailer}";
            };
        };
    };

    environment.systemPackages = [ pkgs.smartmontools ];
}
