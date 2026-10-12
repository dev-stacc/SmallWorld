#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

severity=${SHELLCHECK_SEVERITY:-error}
status=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

shebanged=()
shebangless=()
templates=()

while IFS= read -r f; do
    case "$f" in
        k8s/*)
            templates+=("$f")
            ;;
        *)
            if head -1 "$f" | grep -qE '^#!'; then
                shebanged+=("$f")
            else
                shebangless+=("$f")
            fi
            ;;
    esac
done < <(git ls-files '*.sh')

if [ ${#shebanged[@]} -gt 0 ]; then
    shellcheck --severity="$severity" --format=gcc "${shebanged[@]}" || status=1
fi

if [ ${#shebangless[@]} -gt 0 ]; then
    shellcheck --severity="$severity" --format=gcc --shell=bash "${shebangless[@]}" || status=1
fi

for f in "${templates[@]}"; do
    dest="$tmp/${f//\//_}"
    sed 's/\$\$/$/g' "$f" > "$dest"
    if ! out=$(shellcheck --severity="$severity" --format=gcc --shell=bash "$dest" 2>&1); then
        printf '%s\n' "$out" | sed "s#${dest//#/\\#}#$f#g"
        status=1
    fi
done

if [ "$status" -ne 0 ]; then
    printf '\nshellcheck failed at severity=%s.\n' "$severity" >&2
    exit "$status"
fi

printf 'shellcheck ok at severity=%s: %s with shebangs, %s nix-managed fragments, %s flux templates\n' \
    "$severity" "${#shebanged[@]}" "${#shebangless[@]}" "${#templates[@]}"
