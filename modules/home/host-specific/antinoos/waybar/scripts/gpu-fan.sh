HWMON=$(grep -rl "amdgpu" /sys/class/hwmon/*/name 2>/dev/null | head -1 | xargs dirname)
if [ -n "$HWMON" ]; then
    FAN1=$(cat "$HWMON/fan1_input" 2>/dev/null)
    if [ -n "$FAN1" ] && [ "$FAN1" -gt 0 ]; then
        echo "$FAN1"
    else
        echo "----"
    fi
else
    echo "FIX YOUR GPU FAN !!!"
fi
