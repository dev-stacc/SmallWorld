APPS=$(
    while IFS= read -r file; do
        NAME=$(grep -m1 -E "^Name=" "$file" | cut -d'=' -f2-)
        EXEC=$(grep -m1 -E "^Exec=" "$file" | cut -d'=' -f2- | sed 's/%[a-zA-Z]//g' | sed 's/--untrusted-args//g' | xargs)
        
        if [ -n "$NAME" ] && [ -n "$EXEC" ]; then
            printf '%s\t%s\n' "$NAME" "$EXEC"
        fi
    done < <(find -L \
        /run/current-system/sw/share/applications \
        "$HOME/.nix-profile/share/applications" \
        /etc/profiles/per-user/"$USER"/share/applications \
        "$HOME/.local/share/applications" \
        -maxdepth 1 -name "*.desktop" 2>/dev/null | sort -u)
)

SELECTION=$(printf '%s\n' "$APPS" | fzf --height=40% --border=none --prompt='  Launch: ')

if [ -n "$SELECTION" ]; then
    COMMAND=$(printf '%s' "$SELECTION" | cut -f2-)
    hyprctl dispatch exec $COMMAND
    exit 0
fi