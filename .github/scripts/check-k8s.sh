#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

status=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

crds='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'

dirs=$(find k8s -name kustomization.yaml -printf '%h\n' | sort)

for d in $dirs; do
    out="$tmp/${d//\//_}.yaml"
    if ! err=$(kubectl kustomize "$d" -o "$out" 2>&1); then
        printf 'FAIL  kustomize %s\n' "$d"
        printf '%s\n' "$err" | head -10
        status=1
    fi
done

if [ "$status" -ne 0 ]; then
    printf '\nkustomize rendering failed; schema validation skipped.\n' >&2
    exit "$status"
fi

printf 'kustomize ok: %s overlays rendered\n' "$(printf '%s\n' "$dirs" | wc -l)"

for f in "$tmp"/*.yaml; do
    [ -s "$f" ] || continue
    if ! err=$(kubeconform \
        -strict \
        -ignore-missing-schemas \
        -schema-location default \
        -schema-location "$crds" \
        -summary "$f" 2>&1); then
        printf 'FAIL  kubeconform %s\n' "$(basename "$f" .yaml)"
        printf '%s\n' "$err" | head -20
        status=1
    fi
done

if [ "$status" -ne 0 ]; then
    exit "$status"
fi

printf 'kubeconform ok: all rendered manifests validate\n'
