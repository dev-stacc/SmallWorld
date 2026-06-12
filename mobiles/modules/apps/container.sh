#!/usr/bin/env bash
# modules/apps/container.sh

run_container() {
  mkdir -p "$OUTDIR"
  section "apps/container — staging APKs"

  apkeep -a com.discord              -d apk-pure "$OUTDIR/" &
  apkeep -a com.instagram.android    -d apk-pure "$OUTDIR/" &
  apkeep -a com.zhiliaoapp.musically -d apk-pure "$OUTDIR/" &
  wait
  ok "container APKs staged in $OUTDIR"

  section "apps/container — provisioning managed profile"
  local uid
  uid=$(adb shell pm list users 2>&1 | grep -oE 'UserInfo\{[0-9]+:Container' | grep -oE '[0-9]+' | head -1)
  if [[ -z "$uid" ]]; then
    uid=$(adb shell pm create-user --profileOf 0 --managed Container 2>&1 | grep -oE 'user id [0-9]+' | grep -oE '[0-9]+')
    ok "created container user $uid"
  else
    skip "container user $uid already exists"
  fi
  adb shell pm install-existing --user "$uid" net.typeblog.shelter >/dev/null && ok "Shelter cloned into user $uid"
  adb shell dpm set-profile-owner --user "$uid" net.typeblog.shelter/.receivers.ShelterDeviceAdminReceiver >/dev/null 2>&1 \
    && ok "Shelter is profile owner of user $uid" \
    || skip "profile owner already set"
  adb shell am start-user "$uid" >/dev/null && ok "user $uid started"

  section "apps/container — sideloading"
  adb shell pm install-existing --user "$uid" com.google.android.gms >/dev/null && ok "GMS enabled for user $uid"
  adb shell pm install-existing --user "$uid" com.google.android.gsf >/dev/null && ok "GSF enabled for user $uid"
  install_xapk_user "$OUTDIR/com.discord.xapk"              discord   "$uid" && ok "Discord → user $uid"
  install_xapk_user "$OUTDIR/com.instagram.android.xapk"    instagram "$uid" && ok "Instagram → user $uid"
  install_xapk_user "$OUTDIR/com.zhiliaoapp.musically.xapk" tiktok    "$uid" && ok "TikTok → user $uid"

  section "apps/container — clearing duplicates from user 0"
  for pkg in com.discord com.instagram.android com.zhiliaoapp.musically; do
    adb shell pm uninstall --user 0 "$pkg" >/dev/null 2>&1 && ok "removed $pkg from main" || skip "$pkg not on main"
  done

  section "apps/container — trimming user $uid bloat"
  local U_KEEP=(
    android com.android.systemui com.android.settings com.android.shell com.android.keychain
    com.android.intentresolver com.android.vpndialogs
    com.android.providers.settings com.android.providers.media com.android.providers.downloads
    com.android.providers.contacts com.android.providers.telephony
    com.google.android.networkstack com.google.android.networkstack.tethering
    com.google.android.permissioncontroller com.google.android.packageinstaller
    com.google.android.webview
    com.google.android.gms com.google.android.gsf
    net.typeblog.shelter
    com.discord com.instagram.android com.zhiliaoapp.musically
    com.google.android.providers.media.module com.google.android.modulemetadata
    com.android.bluetooth com.samsung.android.providers.contacts
    com.android.internal.systemui.navbar.gestural com.samsung.internal.systemui.navbar.gestural_no_hint
  )
  declare -A U_KEEP_SET
  for p in "${U_KEEP[@]}"; do U_KEEP_SET[$p]=1; done
  local T_OK=0 T_FAIL=0
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    [[ -n "${U_KEEP_SET[$pkg]:-}" ]] && continue
    if adb shell pm disable-user --user "$uid" "$pkg" </dev/null 2>&1 | grep -q "new state: disabled"; then
      T_OK=$((T_OK+1))
    else
      T_FAIL=$((T_FAIL+1))
    fi
  done < <(adb shell pm list packages --user "$uid" -e | sed 's/package://' | tr -d '\r')
  echo "disabled in user $uid: $T_OK  failed: $T_FAIL"

  section "apps/container — staging KISS trampoline scripts"

  section "apps/container — staging KISS trampoline scripts"
  for s in discord instagram tiktok; do
    adb push "$ROOT/modules/apps/container/$s" /data/local/tmp/ >/dev/null && ok "/data/local/tmp/$s"
  done
  echo ""
  echo "In Termux: pkg install rish termux-tools && rish (authorize via Shizuku),"
  echo "then cp /data/local/tmp/{discord,instagram,tiktok} ~/.shortcuts/ && chmod +x ~/.shortcuts/*"
}
