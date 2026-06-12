#!/usr/bin/env bash
# modules/apps/direct.sh — apps downloaded directly from their official sources

run_direct() {
  mkdir -p "$OUTDIR"
  section "apps/direct — downloading"

  local SIGNAL_URL PMAIL_URL TS_VER
  SIGNAL_URL=$(curl -s "https://updates.signal.org/android/latest.json" | jq -r '.url' | tr -d ' ')
  PMAIL_URL=$(curl -sL "https://api.github.com/repos/ProtonMail/android-mail/releases/latest" \
    | jq -r '.assets[] | select(.name | test(".apk$")) | .browser_download_url')
  TS_VER=$(curl -s "https://pkgs.tailscale.com/stable/" \
    | grep -o 'tailscale-android-universal-[0-9.]*\.apk' | head -1)

  curl -L -o "$OUTDIR/signal.apk"     "$SIGNAL_URL" &
  curl -L -o "$OUTDIR/protonmail.apk" "$PMAIL_URL" &
  curl -L -o "$OUTDIR/tailscale.apk"  "https://pkgs.tailscale.com/stable/$TS_VER" &
  wait
  ok "direct downloads complete"

  section "apps/direct — installing"
  adb install "$OUTDIR/signal.apk"      && ok "Signal"
  adb install "$OUTDIR/protonmail.apk"  && ok "Proton Mail"
  adb install "$OUTDIR/tailscale.apk"   && ok "Tailscale"
}
