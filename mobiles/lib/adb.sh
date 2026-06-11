#!/usr/bin/env bash
# lib/adb.sh — shared helpers, sourced by all modules

adb_ok() {
  adb get-state &>/dev/null || { echo "ERROR: no device connected via ADB"; exit 1; }
}

adb_shell() { adb shell "$@"; }

header() { echo ""; echo "=============================="; echo " $*"; echo "=============================="; }
section() { echo ""; echo "--- $* ---"; }
ok()      { echo "OK   $*"; }
skip()    { echo "SKIP $*"; }
fail()    { echo "FAIL $*"; }

fdroid_latest() {
  local pkg=$1
  curl -s "https://f-droid.org/api/v1/packages/$pkg" \
    | grep -o '"suggestedVersionCode":[0-9]*' | grep -o '[0-9]*'
}

install_xapk() {
  local xapk=$1 name=$2
  local dir="$OUTDIR/${name}-extracted"
  mkdir -p "$dir"
  unzip -o "$xapk" -d "$dir" > /dev/null 2>&1
  adb install-multiple "$dir"/*.apk
}

pm_uninstall() {
  local pkg=$1
  local state
  state=$(adb shell pm list packages --user 0 | grep -x "package:$pkg" || true)
  if [[ -z "$state" ]]; then
    skip "$pkg  (not present)"; return
  fi
  local result
  result=$(adb shell pm uninstall -k --user 0 "$pkg" 2>&1) || true
  if echo "$result" | grep -q "Success"; then
    ok "$pkg"
  else
    fail "$pkg  ($result)"
  fi
}

setting_global() { adb shell settings put global "$1" "$2" && ok "global/$1=$2"; }
setting_secure() { adb shell settings put secure "$1" "$2" && ok "secure/$1=$2"; }
setting_system() { adb shell settings put system "$1" "$2" && ok "system/$1=$2"; }
