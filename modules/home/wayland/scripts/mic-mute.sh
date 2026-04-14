MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -o "MUTED")
if [ -n "$MUTED" ]; then
    echo ""
else
    echo ""
fi