{ pkgs, ... }:
let
  scalePercent = 50;

  cyberpunk-cursors = pkgs.runCommand "cyberpunk2077-cursors" {
    nativeBuildInputs = with pkgs; [ xcur2png imagemagick xorg.xcursorgen ];
  } ''
    out_cursors=$out/share/icons/Cyberpunk2077/cursors
    mkdir -p $out_cursors
    cp ${./cyberpunk2077}/cursor.theme $out/share/icons/Cyberpunk2077/cursor.theme

    work=$(mktemp -d)
    for src in ${./cyberpunk2077}/cursors/*; do
      name=$(basename "$src")
      if [ -L "$src" ]; then
        ln -s "$(readlink "$src")" "$out_cursors/$name"
        continue
      fi

      mkdir -p "$work/$name"
      ( cd "$work/$name" && xcur2png -q -d . -c raw.conf "$src" )

      awk -v s=${toString scalePercent} '
        /^#/ { next }
        NF >= 4 { printf "%d\t%d\t%d\t%s\t%s\n", $1*s/100, $2*s/100, $3*s/100, $4, $5 }
      ' "$work/$name/raw.conf" > "$work/$name/scaled.conf"

      for png in "$work/$name"/*.png; do
        magick "$png" -resize ${toString scalePercent}% "$png"
      done

      ( cd "$work/$name" && xcursorgen scaled.conf "$out_cursors/$name" )
    done
  '';
in {
  home.pointerCursor = {
    enable = true;
    package = cyberpunk-cursors;
    name = "Cyberpunk2077";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
}
