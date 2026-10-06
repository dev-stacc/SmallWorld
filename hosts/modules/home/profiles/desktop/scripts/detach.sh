unit="detach-$(date +%s)-$$"
systemd-run --user --collect --same-dir \
    --setenv=PATH="$PATH" \
    --setenv=SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-}" \
    --unit="$unit" -- "$@"
printf 'journalctl --user -fu %s\n' "$unit"
