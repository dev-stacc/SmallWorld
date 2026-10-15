#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

pkg="${1:?usage: check-searxng-theme.sh <searxng-store-path>}"
css="$pkg/share/static/themes/simple/sxng-ltr.min.css"
mapfile -t templates < <(printf '%s\n' "$pkg"/lib/python3.*/site-packages/searx/templates/simple)

if [ ! -f "$css" ] || [ ! -d "${templates[0]}" ]; then
    printf 'upstream searxng layout unexpected under %s\n' "$pkg"
    exit 1
fi

css_selectors=(
    url_o1
    url_o2
    url_wrapper
    search_logo
    search_header
    search_view
    search_filters
    categories_container
    category_button
    center-alignment-no
    numbered_pagination
    engines_msg
    apis
    sidebar-collapsible
    infobox
    result-images
    backToTop
    links_on_top
)

template_markers=(
    previous_page
    next_page
    url_header
    '{{ endpoint }}_endpoint'
    'class="engines"'
    'class="content"'
)

missing=()
for s in "${css_selectors[@]}"; do
    grep -qF -- "$s" "$css" || missing+=("css:$s")
done

for s in "${template_markers[@]}"; do
    grep -rqF -- "$s" "${templates[@]}" || missing+=("template:$s")
done

if [ "${#missing[@]}" -gt 0 ]; then
    printf 'searxng changed: k8s/apps/searxng/searxng.css targets things no longer present\n'
    printf '  %s\n' "${missing[@]}"
    exit 1
fi

printf 'ok  %d css selectors, %d template markers\n' "${#css_selectors[@]}" "${#template_markers[@]}"
