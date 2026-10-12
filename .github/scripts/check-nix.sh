#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

status=0
hosts=$(nix eval --json --apply builtins.attrNames .#nixosConfigurations | jq -r '.[]')

for h in $hosts; do
    printf 'eval  %-12s ' "$h"
    if drv=$(nix eval --raw ".#nixosConfigurations.$h.config.system.build.toplevel.drvPath" 2>&1); then
        printf 'ok  %s\n' "${drv##*/}"
    else
        printf 'FAIL\n'
        printf '%s\n' "$drv" | tail -20
        status=1
    fi
done

exit "$status"
