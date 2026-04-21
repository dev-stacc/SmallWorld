bars=("▁▁" "▂▂" "▃▃" "▄▄" "▅▅" "▆▆" "▇▇" "██")

mapfile -t s1 < <(awk '/^cpu[0-9]/{print $2+$3+$4+$5, $5}' /proc/stat)
sleep 0.3
mapfile -t s2 < <(awk '/^cpu[0-9]/{print $2+$3+$4+$5, $5}' /proc/stat)
bar_str=""

for i in ${!s1[@]}; do
    read -r t1 i1 <<< "${s1[$i]}"
    read -r t2 i2 <<< "${s2[$i]}"
    dt=$((t2 - t1)); di=$((i2 - i1))
    usage=$(( dt > 0 ? (dt - di) * 100 / dt : 0 ))
    idx=$(( usage * 8 / 100 ))
    [ $idx -gt 7 ] && idx=7
    bar_str+="${bars[$idx]}"
done

echo "$bar_str"