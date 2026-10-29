#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

pkg="${1:?usage: check-fourget-theme.sh <fourget-root-store-path>}"
css="$pkg/static/style.css"
theme="$pkg/static/themes/biggerworld.css"

if [ ! -f "$css" ] || [ ! -f "$theme" ]; then
    printf 'upstream 4get layout unexpected under %s\n' "$pkg"
    exit 1
fi

palette_vars=(
    --1d2021
    --282828
    --3c3836
    --504945
    --928374
    --a89984
    --bdae93
    --8ec07c
    --ebdbb2
    --comment
    --default
    --keyword
    --string
    --green
    --yellow
    --red
)

css_selectors=(
    .navigation
    .searchbox
    .autocomplete
    .tabs
    .filters
    .timetaken
    .text-result
    .right-wrapper
    .right-left
    .right-right
    .greentext
    .thumb-wrap
    .favicon-dropdown
    .spoiler-button
    .info-table
    .nextpage
    .related
    image-wrapper
    "#images"
    "#overflow"
)

markup_markers=(
    'id="overflow" class="web'
    'class="image-wrapper"'
    'class="text-result"'
    'has-answer'
    '<body class="home">'
    'class="tab'
    "static/themes/"
    'DEFAULT_THEME'
)

tab_builder='foreach(["web", "images", "videos", "news", "music"] as $type){'
tab_href='$html .= '"'"'<a href="/'"'"' . $type'

missing=()

for v in "${palette_vars[@]}"; do
    grep -qF -- "$v" "$css" || missing+=("palette:$v")
    grep -qF -- "$v" "$theme" || missing+=("theme-palette:$v")
done

for s in "${css_selectors[@]}"; do
    grep -qF -- "$s" "$css" || missing+=("css:$s")
done

for m in "${markup_markers[@]}"; do
    grep -rqF -- "$m" "$pkg"/template "$pkg"/lib "$pkg"/*.php "$pkg"/data/config.php \
        || missing+=("markup:$m")
done

grep -qF -- "$tab_builder" "$pkg/lib/frontend.php" || missing+=("tabs:type list")
grep -qF -- "$tab_href" "$pkg/lib/frontend.php" || missing+=("tabs:href built as /<type>")

if grep -q '\${' "$theme"; then
    missing+=("theme:unsubstituted \${...} token")
fi

if [ "${#missing[@]}" -gt 0 ]; then
    printf '4get changed: k8s/apps/fourget/fourget.css targets things no longer present\n'
    printf '  %s\n' "${missing[@]}"
    exit 1
fi

printf 'ok  %d palette vars, %d css selectors, %d markup markers, tabs intact\n' \
    "${#palette_vars[@]}" "${#css_selectors[@]}" "${#markup_markers[@]}"
