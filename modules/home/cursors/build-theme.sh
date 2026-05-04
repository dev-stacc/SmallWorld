set -e

SRC="$(dirname "$0")/cursors.jpg"
WORK="/tmp/cyberpunk-cursor-work"
THEME_DIR="$(dirname "$0")/cyberpunk2077"

mkdir -p "$WORK/pngs" "$THEME_DIR/cursors"

crop_cursor() {
    local name="$1" geom="$2" fuzz="$3"
    magick "$SRC" \
        -crop "$geom" +repage \
        -alpha set \
        -fuzz "${fuzz}%" -fill none -draw "color 0,0 floodfill" \
        -trim +repage \
        -gravity center -background none -extent 30x30 \
        "$WORK/pngs/${name}.png"
    echo "  cropped: $name"
}

make_xcursor() {
    local name="$1" hot_x="$2" hot_y="$3"
    echo "30 ${hot_x} ${hot_y} $WORK/pngs/${name}.png" > "$WORK/${name}.cfg"
    xcursorgen "$WORK/${name}.cfg" "$THEME_DIR/cursors/${name}"
    echo "  compiled: $name"
}

echo "==> Cropping cursors..."
crop_cursor default      "90x110+42+28"    35   # arrow (top-left)
crop_cursor crosshair    "85x85+228+88"    35   # + cross
crop_cursor ew-resize    "108x50+80+163"   35   # horizontal ↔
crop_cursor ns-resize    "65x130+55+172"   35   # vertical ↕
crop_cursor nesw-resize  "80x80+140+210"   35   # diagonal ↗↙
crop_cursor nwse-resize  "85x82+203+183"   35   # diagonal ↘↖
crop_cursor wait         "95x95+326+145"   35   # busy red circle
crop_cursor help         "75x75+372+173"   35   # help red circle + arrow
crop_cursor progress     "65x72+420+146"   35   # arrow + small indicator
crop_cursor alias        "58x65+476+183"   35   # arrow variant
crop_cursor text         "40x115+305+205"  10   # I-beam (low fuzz — thin lines)
crop_cursor not-allowed  "90x90+78+308"    35   # X circle
crop_cursor all-scroll   "95x88+204+268"   35   # expand/move
crop_cursor pointer      "48x65+320+330"   35   # hand pointer
crop_cursor grab         "60x75+370+278"   35   # hand + item
crop_cursor copy         "72x65+13+314"    35   # pencil/edit
crop_cursor n-resize     "55x78+495+313"   35   # up arrow

echo "==> Compiling xcursor files..."
make_xcursor default       3   3
make_xcursor crosshair    15  15
make_xcursor ew-resize    15  15
make_xcursor ns-resize    15  15
make_xcursor nesw-resize  15  15
make_xcursor nwse-resize  15  15
make_xcursor wait         15  15
make_xcursor help          3   3
make_xcursor progress      3   3
make_xcursor alias         3   3
make_xcursor text         15  15
make_xcursor not-allowed  15  15
make_xcursor all-scroll   15  15
make_xcursor pointer       9   3
make_xcursor grab          9   3
make_xcursor copy          3  27
make_xcursor n-resize     15  15

echo "==> Creating symlinks..."
cd "$THEME_DIR/cursors"
symlink() { ln -sf "$1" "$2" 2>/dev/null || true; }

symlink default       arrow
symlink default       left_ptr
symlink default       top_left_arrow
symlink text          xterm
symlink text          ibeam
symlink pointer       hand
symlink pointer       hand1
symlink pointer       hand2
symlink pointer       pointing_hand
symlink pointer       openhand
symlink wait          watch
symlink wait          clock
symlink progress      half-busy
symlink progress      left_ptr_watch
symlink all-scroll    move
symlink all-scroll    fleur
symlink all-scroll    size_all
symlink ew-resize     size_hor
symlink ew-resize     h_double_arrow
symlink ns-resize     size_ver
symlink ns-resize     v_double_arrow
symlink nesw-resize   size_bdiag
symlink nwse-resize   size_fdiag
symlink not-allowed   forbidden
symlink not-allowed   no-drop
symlink crosshair     cross
symlink crosshair     tcross
symlink n-resize      up_arrow
symlink grab          closedhand
symlink copy          pencil

cat > "$THEME_DIR/cursor.theme" << 'EOF'
[Icon Theme]
Name=Cyberpunk2077
EOF

echo ""
echo "Done! Theme at: $THEME_DIR"
