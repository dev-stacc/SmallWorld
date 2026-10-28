#!/usr/bin/env bash
set -uo pipefail

ROOTS=("$HOME/BiggerWorld" "$HOME/installer-usb")
for d in "$HOME"/Projects/*/; do ROOTS+=("${d%/}"); done

json_arr() {
    local first=1
    printf '['
    while IFS= read -r l; do
        [ -z "$l" ] && continue
        [ $first -eq 0 ] && printf ','
        first=0
        printf '"%s"' "$(printf '%s' "$l" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    done
    printf ']'
}

work() {
    local d name dirty ahead
    for d in "${ROOTS[@]}"; do
        [ -d "$d/.git" ] || continue
        name=$(basename "$d")
        dirty=$(git -C "$d" status --porcelain 2>/dev/null | wc -l)
        ahead=$(git -C "$d" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
        [ "$dirty" -eq 0 ] && [ "$ahead" -eq 0 ] && continue
        printf '%s  %s uncommitted  %s unpushed\n' "$name" "$dirty" "$ahead"
    done
}

build() {
    local gen age
    gen=$(readlink /nix/var/nix/profiles/system 2>/dev/null | sed "s|.*system-||; s|-link||")
    age=$(( ($(date +%s) - $(stat -c %Y /run/current-system 2>/dev/null || date +%s)) / 3600 ))
    printf 'generation %s  activated %sh ago\n' "${gen:-?}" "$age"
    if [ -n "$(git -C "$HOME/BiggerWorld" status --porcelain 2>/dev/null)" ]; then
        printf 'flake tree dirty  rebuild pending\n'
    fi
    printf 'kernel %s\n' "$(uname -r)"
}

fails() {
    systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1"  failed"}'
    systemctl --user --failed --no-legend --plain 2>/dev/null | awk '{print $1"  failed (user)"}'
    local n
    n=$(journalctl -p3 --since '-24h' -q --no-pager 2>/dev/null | wc -l)
    [ "${n:-0}" -gt 0 ] && printf '%s journal errors  24h\n' "$n"
}

todo() {
    [ -r "$HOME/todo.txt" ] && grep -v "^[[:space:]]*$" "$HOME/todo.txt"
}

printf '{"work":%s,"build":%s,"fails":%s,"todo":%s}\n' \
    "$(work | json_arr)" "$(build | json_arr)" "$(fails | json_arr)" "$(todo | json_arr)"
