pkill -x -u "$(id -u)" ssh-agent || true
loginctl terminate-session "$XDG_SESSION_ID"
