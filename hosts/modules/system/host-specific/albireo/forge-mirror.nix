{ config, pkgs, ... } :
let
    root = "/bigstorage/important/forge";
    endpoint = "http://10.43.132.203:3000";
    api = "${endpoint}/api/v1";

    mirror = pkgs.writeShellScript "forge-mirror" ''
        set -euo pipefail
        git=${pkgs.git}/bin/git
        curl=${pkgs.curl}/bin/curl
        jq=${pkgs.jq}/bin/jq

        token=$(cat ${config.sops.secrets.forgejo-mirror-token.path})

        export GIT_CONFIG_COUNT=1
        export GIT_CONFIG_KEY_0=http.extraHeader
        export GIT_CONFIG_VALUE_0="Authorization: token $token"
        export GIT_TERMINAL_PROMPT=0

        repos='[]'
        page=1
        while [ "$page" -le 50 ]; do
            raw=$($curl -sf --max-time 60 -H "Authorization: token $token" \
                "${api}/repos/search?limit=50&page=$page") || {
                echo "forgejo repo list failed on page $page"
                exit 1
            }
            chunk=$(printf '%s' "$raw" | $jq '.data')
            n=$(printf '%s' "$chunk" | $jq 'length')
            if [ "$n" -eq 0 ]; then
                break
            fi
            repos=$(printf '%s\n%s' "$repos" "$chunk" | $jq -s 'add')
            page=$((page + 1))
        done

        if [ "$page" -gt 50 ]; then
            echo "repo listing did not terminate, paging is wrong"
            exit 1
        fi

        count=$(printf '%s' "$repos" | $jq 'length')
        if [ "$count" -eq 0 ]; then
            echo "forgejo reported zero repositories, refusing to write an empty mirror"
            exit 1
        fi

        mkdir -p ${root}
        rc=0
        mirrored=0

        while IFS="$(printf '\t')" read -r full branch; do
            url=${endpoint}/$full.git
            target=${root}/$full.git
            mkdir -p "$(dirname "$target")"
            ok=0

            if [ -d "$target" ]; then
                if $git -C "$target" remote update --prune; then
                    ok=1
                else
                    echo "update failed for $full"
                    rc=1
                fi
            elif $git clone --quiet --mirror "$url" "$target"; then
                ok=1
            else
                echo "clone failed for $full"
                rc=1
            fi

            if [ "$ok" -eq 1 ]; then
                if $git -C "$target" show-ref --verify --quiet "refs/heads/$branch"; then
                    $git -C "$target" symbolic-ref HEAD "refs/heads/$branch"
                fi
                mirrored=$((mirrored + 1))
            fi
        done < <(printf '%s' "$repos" | $jq -r '.[] | "\(.full_name)\t\(.default_branch)"')

        if [ "$mirrored" -ne "$count" ]; then
            echo "mirrored $mirrored of $count repositories"
            rc=1
        fi

        printf '%s' "$repos" | $jq -r '.[].full_name' | sort > ${root}/MANIFEST
        date -u +%Y-%m-%dT%H:%M:%SZ > ${root}/LAST_SYNC
        echo "mirrored $mirrored of $count repositories into ${root}"
        exit "$rc"
    '';
in {
    sops.secrets.forgejo-mirror-token = {
        sopsFile = ../../../../../secrets/secrets.yaml;
        mode = "0400";
    };

    systemd.services.forge-mirror = {
        description = "Mirror every Forgejo repository into important storage";
        after = [ "network-online.target" "tailscaled.service" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
            Type = "oneshot";
            ExecStart = mirror;
        };
    };

    systemd.timers.forge-mirror = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnCalendar = "23:00";
            RandomizedDelaySec = "15m";
            Persistent = true;
        };
    };
}
