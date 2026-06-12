#!/usr/bin/env bash
# modules/apps/sideload.sh — closed-source apps via APKPure

run_sideload() {
  mkdir -p "$OUTDIR"
  section "apps/sideload — downloading via apkeep"

  apkeep -a us.zoom.videomeetings    -d apk-pure "$OUTDIR/" &
  apkeep -a com.twitter.android      -d apk-pure "$OUTDIR/" &
  apkeep -a com.spotify.music        -d apk-pure "$OUTDIR/" &
  apkeep -a com.here.app.maps        -d apk-pure "$OUTDIR/" &
  wait
  ok "APKPure downloads complete"

  section "apps/sideload — installing"
  adb install "$OUTDIR/com.here.app.maps.apk"  && ok "HERE WeGo"

  install_xapk "$OUTDIR/us.zoom.videomeetings.xapk"    zoom      && ok "Zoom"
  install_xapk "$OUTDIR/com.twitter.android.xapk"      twitter   && ok "Twitter/X"
  install_xapk "$OUTDIR/com.spotify.music.xapk"        spotify   && ok "Spotify"
}
