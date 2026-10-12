{ config, lib, pkgs, tailnet, ... } :
let
    haveSecrets = config.biggerworld.secrets.enable;
    cfg = config.biggerworld.notify;

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

        topic="$(cat ${config.sops.secrets.ntfy-topic.path})"

        post() {
            ${pkgs.curl}/bin/curl -fsS --max-time 10 \
                -H "Title: $title" \
                -H "Priority: $priority" \
                -d "$body" \
                "$@" \
                > /dev/null
        }

        if post "${cfg.endpoint}/$topic"; then
            exit 0
        fi

        post "${cfg.fallback}/$topic" \
            -H "Authorization: Bearer $(cat ${config.sops.secrets.ntfy-token.path})"
    '';
in {
    options.biggerworld.notify = {
        command = lib.mkOption {
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

        endpoint = lib.mkOption {
            type = lib.types.str;
            default = "https://ntfy.${tailnet.domain}";
            description = ''
                Base URL of the ntfy server alerts are posted to, without a topic.

                Defaults to the self-hosted instance on algol, reached over the
                tailnet. Posts are anonymous: the tailnet is the trust boundary and
                the server has no user database, so sending a bearer token it cannot
                verify would be rejected.
            '';
        };

        fallback = lib.mkOption {
            type = lib.types.str;
            default = "https://ntfy.sh";
            description = ''
                Base URL tried only when a post to endpoint fails.

                Reached with the ntfy-token bearer credential. This exists so that
                algol being down - which takes the self-hosted server with it - does
                not silently swallow a disk or UPS alert from any other host.
            '';
        };
    };

    config = lib.mkIf haveSecrets {
        sops.secrets = {
            ntfy-topic.sopsFile = ../../../../../secrets/secrets.yaml;
            ntfy-token.sopsFile = ../../../../../secrets/secrets.yaml;
        };

        biggerworld.notify.command = "${notify}";
    };
}
