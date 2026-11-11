usage() {
    cat <<'USAGE'
usage: sort-music [options]

Sorts finished yt-dlp audio rips into the music library as <dest>/<artist>/<title>.mp3
and repairs the metadata YouTube rips arrive with.

options:
  -s, --src DIR      source directory (default: --paths from the live yt-dlp config)
  -d, --dest DIR     library root (default: ~/media/music)
  -a, --artist NAME  force this artist, overriding whatever the tags claim
  -t, --retitle      rewrite the title tag from the cleaned filename
  -n, --dry-run      report what would happen, change nothing
  -m, --allow-many   proceed even if the batch would create many new artists
  -h, --help         this text

Downloads still in progress are left alone. Audio is never re-encoded: each file is
verified frame-identical before the original is removed, and anything failing
verification is skipped instead of moved.

YouTube rips frequently carry the uploader in the artist tag rather than the musician,
so a batch that would create more than three new artist directories is refused: one
playlist is usually one artist. Rerun with --artist NAME to override the tags, or
--allow-many to accept them as they stand.
USAGE
}

max_new=3

src=""
dest="$HOME/media/music"
artist_override=""
retitle=0
dry=0
allow_many=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        -s|--src) src="${2:-}"; shift 2 ;;
        -d|--dest) dest="${2:-}"; shift 2 ;;
        -a|--artist) artist_override="${2:-}"; shift 2 ;;
        -t|--retitle) retitle=1; shift ;;
        -n|--dry-run) dry=1; shift ;;
        -m|--allow-many) allow_many=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'sort-music: unknown argument %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

if [ -z "$src" ]; then
    cfg="${XDG_CONFIG_HOME:-$HOME/.config}/yt-dlp/config"
    if [ -r "$cfg" ]; then
        src=$(sed -nE 's/^[[:space:]]*--paths[[:space:]]+//p' "$cfg" | tail -1)
        src=${src#home:}
    fi
fi

if [ -z "$src" ]; then
    printf 'sort-music: no source directory, and none in the yt-dlp config\n' >&2
    exit 2
fi

if [ ! -d "$src" ]; then
    printf 'sort-music: source directory %s does not exist\n' "$src" >&2
    exit 2
fi

tag() {
    ffprobe -v error -show_entries "format_tags=$2" -of default=nw=1:nk=1 "$1" 2>/dev/null | head -1
}

cover() {
    ffprobe -v error -select_streams v -show_entries stream=codec_name \
        -of default=nw=1:nk=1 "$1" 2>/dev/null | head -1
}

frames() {
    ffmpeg -v error -i "$1" -map 0:a -c copy -f md5 - 2>/dev/null
}

is_youtube_category() {
    case "$1" in
        Music|Gaming|Comedy|Entertainment|Education|Sports|Trailers|Shows|\
        "People & Blogs"|"Film & Animation"|"Autos & Vehicles"|"Pets & Animals"|\
        "Howto & Style"|"News & Politics"|"Science & Technology"|"Travel & Events"|\
        "Nonprofits & Activism") return 0 ;;
        *) return 1 ;;
    esac
}

busy() {
    local f=$1 base size_a size_b ext
    base=${f%.*}
    for ext in part ytdl temp mp4 mkv webm m4a opus webp; do
        if [ -e "$base.$ext" ]; then
            return 0
        fi
    done
    size_a=$(stat -c %s "$f")
    sleep 2
    size_b=$(stat -c %s "$f")
    if [ "$size_a" != "$size_b" ]; then
        return 0
    fi
    return 1
}

escape() {
    printf '%s' "$1" | sed -E 's@[][\\.^$*+?(){}|/&]@\\&@g' | sed -E 's/[[:space:]]+/[[:space:]]*/g'
}

clean_name() {
    local raw=$1 artist=$2 out pattern
    out=${raw%.*}
    if [ -n "$artist" ]; then
        pattern=$(escape "$artist")
        out=$(printf '%s' "$out" | sed -E "s/$pattern//Ig")
    fi
    out=$(printf '%s' "$out" | sed -E '
        s/⧸/ - /g
        s/^[[:space:].]+//
        s/^[[:space:]]*[-–—:|][[:space:]]*//
        s/[[:space:]]*[-–—:|][[:space:]]*$//
        s/[[:space:]]+/ /g
        s/^[[:space:]]+//
        s/[[:space:]]+$//
    ')
    if [ -z "$out" ]; then
        out=$(printf '%s' "${raw%.*}" | sed -E 's/^[.]+//')
    fi
    printf '%s' "$out"
}

resolve_artist() {
    local f=$1 a
    if [ -n "$artist_override" ]; then
        printf '%s' "$artist_override"
        return 0
    fi
    a=$(tag "$f" album_artist)
    if [ -z "$a" ]; then
        a=$(tag "$f" artist)
    fi
    a=${a%%,*}
    a=${a%%;*}
    a=$(printf '%s' "$a" | sed -E 's/[[:space:]]*[([]?[[:space:]]*(feat|ft|with)\.?[[:space:]].*$//I')
    printf '%s' "$a" | sed -E 's@/@-@g; s/^[[:space:].]+//; s/[[:space:]]+$//'
}

declare -a plan_file=()
declare -a plan_artist=()
declare -a plan_title=()

sorted=0
skipped=0
waiting=0
failed=0

shopt -s nullglob dotglob
for f in "$src"/*.mp3; do
    base=$(basename "$f")

    if busy "$f"; then
        printf 'waiting   %s (download in progress)\n' "$base"
        waiting=$((waiting + 1))
        continue
    fi

    artist=$(resolve_artist "$f")
    if [ -z "$artist" ]; then
        printf 'no artist %s (rerun with --artist)\n' "$base"
        skipped=$((skipped + 1))
        continue
    fi

    title=$(clean_name "$base" "$artist")

    if [ -e "$dest/$artist/$title.mp3" ]; then
        printf 'exists    %s -> %s/%s.mp3\n' "$base" "$artist" "$title"
        skipped=$((skipped + 1))
        continue
    fi

    plan_file+=("$f")
    plan_artist+=("$artist")
    plan_title+=("$title")
done

if [ "${#plan_file[@]}" -eq 0 ]; then
    printf -- '---\n'
    printf 'nothing to sort (skipped %s, waiting %s)\n' "$skipped" "$waiting"
    exit 0
fi

new_count=0
while read -r a; do
    if [ -n "$a" ] && [ ! -d "$dest/$a" ]; then
        new_count=$((new_count + 1))
    fi
done < <(printf '%s\n' "${plan_artist[@]}" | sort -u)

if [ "$new_count" -gt "$max_new" ] && [ -z "$artist_override" ] && [ "$allow_many" -eq 0 ]; then
    printf 'sort-music: this batch would create %s new artist directories:\n' "$new_count" >&2
    printf '%s\n' "${plan_artist[@]}" | sort | uniq -c | sort -rn >&2
    printf 'that usually means the artist tag holds the uploader, not the musician.\n' >&2
    printf 'rerun with --artist NAME to override, or --allow-many to accept these.\n' >&2
    exit 3
fi

work=""
cleanup() {
    if [ -n "$work" ] && [ -d "$work" ]; then
        rm -rf "$work"
    fi
}
trap cleanup EXIT

if [ "$dry" -eq 0 ]; then
    work=$(mktemp -d)
fi

i=0
while [ "$i" -lt "${#plan_file[@]}" ]; do
    f=${plan_file[$i]}
    artist=${plan_artist[$i]}
    title=${plan_title[$i]}
    base=$(basename "$f")
    i=$((i + 1))

    declare -a meta=()
    if [ -n "$artist_override" ]; then
        meta+=(-metadata "artist=$artist")
    fi
    if [ "$(tag "$f" album_artist)" != "$artist" ]; then
        meta+=(-metadata "album_artist=$artist")
    fi
    if [ "$retitle" -eq 1 ] && [ "$(tag "$f" title)" != "$title" ]; then
        meta+=(-metadata "title=$title")
    fi
    genre=$(tag "$f" genre)
    if [ -n "$genre" ] && is_youtube_category "$genre"; then
        meta+=(-metadata "genre=")
    fi

    changes=$((${#meta[@]} / 2))

    if [ "$dry" -eq 1 ]; then
        printf 'would     %s -> %s/%s.mp3 [%s tag changes]\n' "$base" "$artist" "$title" "$changes"
        sorted=$((sorted + 1))
        unset meta
        continue
    fi

    mkdir -p "$dest/$artist"
    target="$dest/$artist/$title.mp3"

    if [ "$changes" -eq 0 ]; then
        mv -n "$f" "$target"
        printf 'moved     %s -> %s/%s.mp3\n' "$base" "$artist" "$title"
        sorted=$((sorted + 1))
        unset meta
        continue
    fi

    staged="$work/$title.mp3"
    if ! ffmpeg -v error -y -i "$f" -map 0 -c copy "${meta[@]}" "$staged" 2>"$work/err"; then
        printf 'FAILED    %s :: %s\n' "$base" "$(head -1 "$work/err")" >&2
        failed=$((failed + 1))
        rm -f "$staged"
        unset meta
        continue
    fi

    if [ "$(frames "$f")" != "$(frames "$staged")" ]; then
        printf 'FAILED    %s :: audio frames changed, left in place\n' "$base" >&2
        failed=$((failed + 1))
        rm -f "$staged"
        unset meta
        continue
    fi

    cover_before=$(cover "$f")
    if [ -n "$cover_before" ] && [ "$cover_before" != "$(cover "$staged")" ]; then
        printf 'FAILED    %s :: cover art lost, left in place\n' "$base" >&2
        failed=$((failed + 1))
        rm -f "$staged"
        unset meta
        continue
    fi

    touch -r "$f" "$staged"
    mv -n "$staged" "$target"
    rm -f "$f"
    printf 'sorted    %s -> %s/%s.mp3 [%s tag changes]\n' "$base" "$artist" "$title" "$changes"
    sorted=$((sorted + 1))
    unset meta
done

printf -- '---\n'
if [ "$dry" -eq 1 ]; then
    printf 'would sort %s, skip %s, wait on %s\n' "$sorted" "$skipped" "$waiting"
else
    printf 'sorted %s, skipped %s, waiting %s, failed %s\n' "$sorted" "$skipped" "$waiting" "$failed"
fi

if [ "$failed" -gt 0 ]; then
    exit 1
fi
