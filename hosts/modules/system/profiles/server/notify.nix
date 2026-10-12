{ config, lib, pkgs, ... } :
let
    haveSecrets = config.biggerworld.secrets.enable;

    notify = pkgs.writeShellScript "ntfy-notify" ''
        set -eu

        title="''${NOTIFY_TITLE:-BiggerWorld}"
        priority="''${NOTIFY_PRIORITY:-high}"

        if [ "$#" -gt 0 ]; then
            body="$*"
        elif [ -n "''${SMARTD_MESSAGE:-}" ]; then
            body="$(${pkgs.inetutils}/bin/hostname): ''${SMARTD_MESSAGE}"
        elif [ -n "''${UPSMON_MESSAGE:-}" ]; then
            body="$(${pkgs.inetutils}/bin/hostname): ''${UPSMON_MESSAGE}"
        else
            body="$(cat)"
        fi

        ${pkgs.curl}/bin/curl -fsS \
            -H "Authorization: Bearer $(cat ${config.sops.secrets.ntfy-token.path})" \
            -H "Title: $title" \
            -H "Priority: $priority" \
            -d "$body" \
            "https://ntfy.sh/$(cat ${config.sops.secrets.ntfy-topic.path})" \
            > /dev/null
    '';
in {
    options.biggerworld.notify.command = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
            Shell command that posts its arguments to ntfy as this fleet.

            Empty on hosts without secret access, so every consumer must treat
            an empty value as "no notification path available" and fall back to
            the journal. Set NOTIFY_TITLE or NOTIFY_PRIORITY in the environment
            to override the defaults.
        '';
    };

    config = lib.mkIf haveSecrets {
        sops.secrets = {
            ntfy-topic.sopsFile = ../../../../../secrets/secrets.yaml;
            ntfy-token.sopsFile = ../../../../../secrets/secrets.yaml;
        };

        biggerworld.notify.command = "${notify}";
    };
}
