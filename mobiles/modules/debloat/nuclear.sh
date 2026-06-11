#!/usr/bin/env bash
# modules/debloat/nuclear.sh
# Whitelist-based disable: every package not in KEEP is disabled.
# Uses pm list packages (no -e) to catch disabled-until-used packages.
# Safe: pm disable-user --user 0 is fully reversible.
# User apps: uninstalled with -k (restorable via cmd package install-existing).

run_nuclear() {
  local KEEP=(
    # Core Android — boot / UI
    android
    com.android.systemui
    com.android.settings
    com.android.shell
    com.android.keychain
    com.android.bluetooth
    com.android.intentresolver
    com.android.vpndialogs

    # Providers
    com.android.providers.settings
    com.android.providers.telephony
    com.android.providers.downloads
    com.android.providers.media

    # Telephony stack
    com.android.phone
    com.android.server.telecom
    com.android.mms.service
    com.android.location.fused          # E911

    # Samsung providers (storage backends — keep even after UI replaced)
    com.samsung.android.providers.contacts
    com.samsung.android.providers.media

    # SMS/MMS backend
    com.samsung.android.messaging

    # VoLTE / WiFi calling
    com.sec.imsservice
    com.sec.epdg
    com.sec.unifiedwfc

    # Launcher (back button depends on this — do not remove)
    com.sec.android.app.launcher

    # Network stack (OEM unlock + data + VoLTE)
    com.google.android.networkstack
    com.google.android.networkstack.tethering
    com.samsung.android.networkstack
    com.samsung.android.networkstack.tethering.overlay
    com.samsung.android.wifi.resources
    com.samsung.android.wifi.softap.resources
    com.samsung.android.wifi.softapwpathree.resources

    # OEM unlock path — Samsung server auth
    com.samsung.android.fmm
    com.samsung.klmsagent
    com.samsung.android.kgclient
    com.knox.vpn.proxyhandler

    # Biometrics / TrustZone (PIN + fingerprint)
    com.samsung.sec.android.teegris.tui_service
    com.samsung.android.biometrics.app.setting

    # Emergency
    com.samsung.android.emergency
    com.google.android.cellbroadcastreceiver
    com.google.android.cellbroadcastservice

    # Permission dialogs + ADB installs
    com.google.android.permissioncontroller
    com.google.android.packageinstaller

    # Navbar overlays (all variants — one is active)
    com.android.internal.systemui.navbar.gestural
    com.android.internal.systemui.navbar.gestural_extra_wide_back
    com.android.internal.systemui.navbar.gestural_narrow_back
    com.android.internal.systemui.navbar.gestural_wide_back
    com.android.internal.systemui.navbar.threebutton
    com.samsung.internal.systemui.navbar.gestural_no_hint
    com.samsung.internal.systemui.navbar.swipe_up_wide
    com.samsung.internal.systemui.navbar.threebutton
  )

  declare -A KEEP_SET
  for pkg in "${KEEP[@]}"; do KEEP_SET[$pkg]=1; done

  section "debloat/nuclear — disabling system packages"
  local ENABLED OK=0 SKIP=0 FAIL=()
  ENABLED=$(adb shell pm list packages --user 0 | sed 's/package://' | tr -d '\r')

  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    if [[ -n "${KEEP_SET[$pkg]:-}" ]]; then SKIP=$((SKIP+1)); continue; fi
    local result
    result=$(adb shell pm disable-user --user 0 "$pkg" 2>&1) || true
    if echo "$result" | grep -q "new state: disabled"; then
      ok "$pkg"; OK=$((OK+1))
    else
      echo "??   $pkg  ($result)"; FAIL+=("$pkg")
    fi
  done <<< "$ENABLED"

  echo ""
  echo "Disabled: $OK  |  Kept: $SKIP  |  Failed: ${#FAIL[@]}"
  for f in "${FAIL[@]}"; do fail "$f"; done

  section "debloat/nuclear — uninstalling user apps"
  local USER_APPS U_OK=0 U_FAIL=()
  USER_APPS=$(adb shell pm list packages -3 --user 0 | sed 's/package://' | tr -d '\r')

  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    local result
    result=$(adb shell pm uninstall -k --user 0 "$pkg" 2>&1) || true
    if echo "$result" | grep -q "Success"; then
      ok "$pkg"; U_OK=$((U_OK+1))
    else
      echo "??   $pkg  ($result)"; U_FAIL+=("$pkg")
    fi
  done <<< "$USER_APPS"

  echo ""
  echo "Uninstalled: $U_OK  |  Failed: ${#U_FAIL[@]}"
  for f in "${U_FAIL[@]}"; do fail "$f"; done
}
