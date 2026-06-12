#!/usr/bin/env bash
# android.sh — entry point
# Usage: ./android.sh [device] [module]
#   device  folder under devices/           (default: Algol)
#   module  all | debloat | apps | config   (default: all)
#           or group/submodule, e.g. config/privacy
#
# Runs inside nix-shell automatically if adb is not in PATH.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEVICE="${1:-Algol}"
MODULE="${2:-all}"

if ! command -v adb &>/dev/null; then
  exec nix-shell -p android-tools apkeep unzip jq curl --run "bash $0 $*"
fi

source "$ROOT/lib/adb.sh"
source "$ROOT/lib/keep.sh"
source "$ROOT/devices/$DEVICE/default.sh"

adb_ok

header "android.sh — $DEVICE"
echo "  module : $MODULE"
echo ""

_source_group() {
  local group="$1"
  local dir="$ROOT/modules/$group"
  for f in "$dir"/*.sh; do
    [[ "$(basename "$f")" == "default.sh" ]] && continue
    source "$f"
  done
  source "$dir/default.sh"
}

case "$MODULE" in
  all)
    _source_group debloat; run_debloat
    _source_group apps;    run_apps
    _source_group config;  run_config
    ;;
  debloat|apps|config)
    _source_group "$MODULE"; "run_$MODULE"
    ;;
  */*)
    group="${MODULE%%/*}"
    sub="${MODULE##*/}"
    _source_group "$group"
    "run_${sub}"
    ;;
  *)
    echo "unknown module: $MODULE"
    echo "usage: $0 [device] [all|debloat|apps|config|debloat/nuclear|apps/fdroid|config/privacy|...]"
    exit 1
    ;;
esac
