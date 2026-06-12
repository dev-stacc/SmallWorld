#!/usr/bin/env bash
# modules/apps/container.sh

run_container() {
  mkdir -p "$OUTDIR"
  section "apps/container — staging APKs for sandboxed sideload"

  apkeep -a com.google.android.gms   -d apk-pure "$OUTDIR/" &
  apkeep -a com.google.android.gsf   -d apk-pure "$OUTDIR/" &
  apkeep -a com.discord              -d apk-pure "$OUTDIR/" &
  apkeep -a com.instagram.android    -d apk-pure "$OUTDIR/" &
  apkeep -a com.zhiliaoapp.musically -d apk-pure "$OUTDIR/" &
  wait
  ok "Container APKs staged in $OUTDIR"

  section "apps/container — manual install"
  cat <<EOF
Once Shelter has provisioned the container:
  1. adb shell pm list users   # note the container user id (e.g. 10)
  2. For each APK / XAPK in $OUTDIR, install into that user, e.g.:
       install_xapk_user $OUTDIR/com.google.android.gms.xapk gms <user_id>
       install_xapk_user $OUTDIR/com.google.android.gsf.xapk gsf <user_id>
       install_xapk_user $OUTDIR/com.discord.xapk            discord <user_id>
       install_xapk_user $OUTDIR/com.instagram.android.xapk  instagram <user_id>
       install_xapk_user $OUTDIR/com.zhiliaoapp.musically.xapk tiktok <user_id>
  Single-APK packages can use: adb install --user <user_id> <file.apk>
EOF
}
