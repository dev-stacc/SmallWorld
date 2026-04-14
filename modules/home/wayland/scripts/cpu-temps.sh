TEMP_LOCATION=$(grep -rl "x86_pkg_temp" /sys/class/thermal/thermal_zone*/type 2>/dev/null | head -1 | xargs dirname)

if [ -n "$TEMP_LOCATION" ]; then
    CPU_TEMP=$(cat "$TEMP_LOCATION/temp" 2>/dev/null)
    if [ -n "$CPU_TEMP" ]; then
        echo "$CPU_TEMP"
    else
        echo "FIX YOUR CPU TEMPS !!! (no temps)"
    fi
else
    echo "FIX YOUR CPU TEMPS !!! (no sensor)"
fi