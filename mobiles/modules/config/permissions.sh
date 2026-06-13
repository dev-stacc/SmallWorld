#!/usr/bin/env bash
# modules/config/permissions.sh — app roles and permission lockdowns

run_permissions() {
  section "config/permissions — Fossify Phone as default dialer"
  adb shell cmd role add-role-holder android.app.role.DIALER org.fossify.phone 0 \
    && ok "dialer role → org.fossify.phone"
  adb shell pm disable-user --user 0 com.samsung.android.dialer   2>/dev/null || true
  adb shell pm disable-user --user 0 com.samsung.android.incallui 2>/dev/null || true
  adb shell pm disable-user --user 0 com.samsung.android.app.contacts 2>/dev/null || true

  section "config/permissions — Samsung Home as default home"
  adb shell cmd role add-role-holder android.app.role.HOME com.sec.android.app.launcher 0 \
    && ok "home role → com.sec.android.app.launcher"

  section "config/permissions — Heliboard as default IME"
  adb shell ime enable helium314.keyboard/.latin.LatinIME >/dev/null \
    && adb shell ime set helium314.keyboard/.latin.LatinIME >/dev/null \
    && ok "IME → Heliboard"


  section "config/permissions — IronFox lockdown"
  for perm in \
    android.permission.ACCESS_FINE_LOCATION \
    android.permission.ACCESS_COARSE_LOCATION \
    android.permission.READ_CONTACTS \
    android.permission.RECORD_AUDIO \
    android.permission.CAMERA; do
    adb shell pm revoke org.ironfoxoss.ironfox "$perm" 2>/dev/null || true
  done
  ok "IronFox sensitive permissions revoked"
}
