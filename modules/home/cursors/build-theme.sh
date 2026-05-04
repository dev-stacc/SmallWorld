set -e

ZIP="$(cd "$(dirname "$0")"; pwd)/models/cyberpunk-original.zip"
WORK="/tmp/cyberpunk-cursor-work"
THEME_DIR="$(cd "$(dirname "$0")"; pwd)/cyberpunk2077"

rm -rf "$WORK"
mkdir -p "$WORK/cur" "$WORK/pngs" "$THEME_DIR/cursors"

echo "==> Extracting cursors from zip..."
unzip -o -d "$WORK/cur" "$ZIP"

read_u16_le() {
    od -An -tu2 -j"$2" -N2 "$1" | tr -d ' \n'
}

convert_cursor() {
    local name="$1" src="$2"
    local hot_x hot_y size png cfg tmp

    png="$WORK/pngs/${name}.png"
    cfg="$WORK/${name}.cfg"
    tmp="$WORK/cur/tmp_input.cur"

    hot_x=$(read_u16_le "$WORK/cur/$src" 10)
    hot_y=$(read_u16_le "$WORK/cur/$src" 12)

    cp "$WORK/cur/$src" "$tmp"
    magick "${tmp}[0]" -alpha set "$png"
    size=$(magick identify -format "%w" "$png")

    echo "$size $hot_x $hot_y $png" > "$cfg"
    xcursorgen "$cfg" "$THEME_DIR/cursors/$name"
    echo "  $name: ${size}px hotspot=(${hot_x},${hot_y})"
}

echo "==> Converting cursors..."
convert_cursor default      "1 - Normal Select.cur"
convert_cursor help         "2 - Help Select.cur"
convert_cursor progress     "3 - Working In Background.cur"
convert_cursor wait         "4 - Busy.cur"
convert_cursor crosshair    "5 - Precision Select.cur"
convert_cursor text         "6 - Text Select.cur"
convert_cursor copy         "7 - Handwriting.cur"
convert_cursor not-allowed  "8 - Unavailable.cur"
convert_cursor ns-resize    "9 - Vertical Resize.cur"
convert_cursor ew-resize    "10 - Horizontal Resize.cur"
convert_cursor nesw-resize  "11 - Diagonal Resize 1.cur"
convert_cursor nwse-resize  "12 - Diagonal Resize 2.cur"
convert_cursor all-scroll   "13 - Move.cur"
convert_cursor alias        "14 - Alternate Select.cur"
convert_cursor pointer      "15 - Link Select.cur"

echo "==> Creating symlinks..."
cd "$THEME_DIR/cursors"
lns() { ln -sf "$1" "$2" 2>/dev/null || true; }

lns default     arrow
lns default     left_ptr
lns default     top_left_arrow
lns text        xterm
lns text        ibeam
lns pointer     hand
lns pointer     hand1
lns pointer     hand2
lns pointer     pointing_hand
lns pointer     openhand
lns pointer     grab
lns pointer     closedhand
lns wait        watch
lns wait        clock
lns progress    half-busy
lns progress    left_ptr_watch
lns all-scroll  move
lns all-scroll  fleur
lns all-scroll  size_all
lns ew-resize   size_hor
lns ew-resize   h_double_arrow
lns ns-resize   size_ver
lns ns-resize   v_double_arrow
lns ns-resize   n-resize
lns ns-resize   up_arrow
lns nesw-resize size_bdiag
lns nwse-resize size_fdiag
lns not-allowed forbidden
lns not-allowed no-drop
lns crosshair   cross
lns crosshair   tcross
lns copy        pencil

cat > "$THEME_DIR/cursor.theme" <<'EOF'
[Icon Theme]
Name=Cyberpunk2077
EOF

echo ""
echo "Done! Theme at: $THEME_DIR"
