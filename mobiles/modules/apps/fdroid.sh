#!/usr/bin/env bash
# modules/apps/fdroid.sh — download and install F-Droid apps

run_fdroid() {
  section "apps/fdroid — fetching latest version codes"
  local KISS_VER HELI_VER MSG_VER CAM_VER GAL_VER
  local TERMUX_VER TERMUX_API_VER FM_VER CLK_VER CAL_VER CON_VER PHN_VER NP_VER

  KISS_VER=$(fdroid_latest fr.neamar.kiss)
  HELI_VER=$(fdroid_latest helium314.keyboard)
  MSG_VER=$(fdroid_latest org.fossify.messages)
  CAM_VER=$(fdroid_latest org.fossify.camera)
  GAL_VER=$(fdroid_latest org.fossify.gallery)
  TERMUX_VER=$(fdroid_latest com.termux)
  TERMUX_API_VER=$(fdroid_latest com.termux.api)
  FM_VER=$(fdroid_latest org.fossify.filemanager)
  CLK_VER=$(fdroid_latest org.fossify.clock)
  CAL_VER=$(fdroid_latest org.fossify.calendar)
  CON_VER=$(fdroid_latest org.fossify.contacts)
  PHN_VER=$(fdroid_latest org.fossify.phone)
  NP_VER=$(fdroid_latest org.schabi.newpipe)

  mkdir -p "$OUTDIR"

  section "apps/fdroid — downloading"
  curl -L -o "$OUTDIR/kiss.apk"               "https://f-droid.org/repo/fr.neamar.kiss_${KISS_VER}.apk" &
  curl -L -o "$OUTDIR/heliboard.apk"          "https://f-droid.org/repo/helium314.keyboard_${HELI_VER}.apk" &
  curl -L -o "$OUTDIR/fossify-messages.apk"   "https://f-droid.org/repo/org.fossify.messages_${MSG_VER}.apk" &
  curl -L -o "$OUTDIR/fossify-camera.apk"     "https://f-droid.org/repo/org.fossify.camera_${CAM_VER}.apk" &
  curl -L -o "$OUTDIR/fossify-gallery.apk"    "https://f-droid.org/repo/org.fossify.gallery_${GAL_VER}.apk" &
  curl -L -o "$OUTDIR/termux.apk"             "https://f-droid.org/repo/com.termux_${TERMUX_VER}.apk" &
  curl -L -o "$OUTDIR/termux-api.apk"         "https://f-droid.org/repo/com.termux.api_${TERMUX_API_VER}.apk" &
  curl -L -o "$OUTDIR/fossify-filemanager.apk" "https://f-droid.org/repo/org.fossify.filemanager_${FM_VER}.apk" &
  curl -L -o "$OUTDIR/fossify-clock.apk"      "https://f-droid.org/repo/org.fossify.clock_${CLK_VER}.apk" &
  curl -L -o "$OUTDIR/fossify-calendar.apk"   "https://f-droid.org/repo/org.fossify.calendar_${CAL_VER}.apk" &
  curl -L -o "$OUTDIR/fossify-contacts.apk"   "https://f-droid.org/repo/org.fossify.contacts_${CON_VER}.apk" &
  curl -L -o "$OUTDIR/fossify-phone.apk"      "https://f-droid.org/repo/org.fossify.phone_${PHN_VER}.apk" &
  curl -L -o "$OUTDIR/newpipe.apk"            "https://f-droid.org/repo/org.schabi.newpipe_${NP_VER}.apk" &
  wait
  ok "F-Droid downloads complete"

  section "apps/fdroid — installing"
  adb install "$OUTDIR/kiss.apk"                && ok "KISS Launcher"
  adb install "$OUTDIR/heliboard.apk"           && ok "Heliboard"
  adb install "$OUTDIR/fossify-phone.apk"       && ok "Fossify Phone"
  adb install "$OUTDIR/fossify-contacts.apk"    && ok "Fossify Contacts"
  adb install "$OUTDIR/fossify-messages.apk"    && ok "Fossify Messages"
  adb install "$OUTDIR/fossify-camera.apk"      && ok "Fossify Camera"
  adb install "$OUTDIR/fossify-gallery.apk"     && ok "Fossify Gallery"
  adb install "$OUTDIR/fossify-filemanager.apk" && ok "Fossify File Manager"
  adb install "$OUTDIR/fossify-clock.apk"       && ok "Fossify Clock"
  adb install "$OUTDIR/fossify-calendar.apk"    && ok "Fossify Calendar"
  adb install "$OUTDIR/termux.apk"              && ok "Termux"
  adb install "$OUTDIR/termux-api.apk"          && ok "Termux:API"
  adb install "$OUTDIR/newpipe.apk"             && ok "NewPipe"
}
