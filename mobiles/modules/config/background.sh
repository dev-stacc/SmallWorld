#!/usr/bin/env bash
# modules/config/background.sh

run_background() {
  section "config/background — doze whitelist"
  local PKGS=(
    org.fossify.messages
    org.fossify.phone
    org.thoughtcrime.securesms
    ch.protonmail.android
    com.tailscale.ipn
    io.heckel.ntfy
  )
  for pkg in "${PKGS[@]}"; do
    adb shell dumpsys deviceidle whitelist "+$pkg" >/dev/null && ok "$pkg"
  done

  section "config/background — notification audio routing"
  setting_global sync_parent_sounds 1
  setting_system sync_parent_sounds 1
}
