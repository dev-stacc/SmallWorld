#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

marker='ENC\[AES256_GCM'
allowlist=.github/encrypted-paths
status=0

fail() {
    printf 'FAIL  %s\n' "$1" >&2
    status=1
}

encrypted() {
    grep -q "$marker" "$1" 2>/dev/null
}

while IFS= read -r f; do
    encrypted "$f" || fail "$f: lives under secrets/ but is not sops-encrypted"
done < <(git ls-files secrets/)

while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ ! -f "$f" ]; then
        fail "$f: listed in $allowlist but is not in the tree (remove it from the list, or restore the file)"
    elif ! encrypted "$f"; then
        fail "$f: listed in $allowlist but is not sops-encrypted"
    fi
done < "$allowlist"

while IFS= read -r f; do
    if grep -qE '^kind:[[:space:]]*["'"'"']?Secret["'"'"']?[[:space:]]*$' "$f"; then
        fail "$f: declares a Kubernetes Secret in plaintext"
    fi
done < <(git ls-files 'k8s/*.yaml' 'k8s/*.yml')

if [ "$status" -ne 0 ]; then
    printf '\nsops encrypts every value in this repo, so an encrypted manifest reads "kind: ENC[...]".\n' >&2
    printf 'A literal "kind: Secret" means the file was committed before sops ran over it.\n' >&2
    printf 'Re-encrypt with: sops --encrypt --in-place <file>\n' >&2
    exit "$status"
fi

printf 'secret hygiene ok: %s under secrets/, %s on the allowlist, no plaintext Secret manifests\n' \
    "$(git ls-files secrets/ | wc -l)" "$(grep -cve '^$' "$allowlist")"
