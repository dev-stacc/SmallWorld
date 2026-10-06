HWMON=$(grep -rl "coretemp" /sys/class/hwmon/*/name 2>/dev/null | head -1 | xargs dirname)
if [ -n "$HWMON" ]; then
    TEMP=$(cat "$HWMON/temp1_input" 2>/dev/null)
    if [ -n "$TEMP" ]; then
        echo $((TEMP / 1000))
    else
        echo "FIX YOUR CPU TEMPS !!! (no temps)"
    fi
else
    echo "FIX YOUR CPU TEMPS !!! (no sensor)"
fi
