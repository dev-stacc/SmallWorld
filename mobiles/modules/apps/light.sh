#!/usr/bin/env bash
# modules/apps/light.sh — minimal app install: launcher swap + Aurora alongside Play

run_light() {
  mkdir -p "$OUTDIR"

  section "apps/light — fetching latest versions"
  local AURORA_VER LAWN_URL
  AURORA_VER=$(fdroid_latest com.aurora.store)
  # Lawnchair 15 ships only as prereleases; /releases/latest returns the ancient v12.
  # Pick newest non-nightly prerelease, skip Debug/Nightly CI assets.
  LAWN_URL=$(curl -sL "https://api.github.com/repos/LawnchairLauncher/lawnchair/releases?per_page=10" \
    | jq -r '[.[] | select(.tag_name != "nightly")][0].assets[]
             | select(.name | test("Nightly|Debug") | not)
             | .browser_download_url' | head -1)

  section "apps/light — downloading"
  curl -L -o "$OUTDIR/lawnchair.apk" "$LAWN_URL" &
  curl -L -o "$OUTDIR/aurora.apk"    "https://f-droid.org/repo/com.aurora.store_${AURORA_VER}.apk" &
  wait
  ok "downloads complete"

  section "apps/light — installing"
  adb install "$OUTDIR/lawnchair.apk" && ok "Lawnchair"
  adb install "$OUTDIR/aurora.apk"    && ok "Aurora Store"
}
