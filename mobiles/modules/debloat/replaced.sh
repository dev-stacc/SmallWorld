#!/usr/bin/env bash
# modules/debloat/replaced.sh
# Uninstall disabled packages that have been replaced by installed apps.

run_replaced() {
  section "debloat/replaced — uninstalling replaced packages"
  local PKGS=(
    # Fossify Phone replaces
    com.samsung.android.dialer
    com.samsung.android.incallui
    com.samsung.android.app.contacts
    com.samsung.android.app.telephonyui
    com.samsung.android.app.telephonyui.esimclient
    com.sec.phone

    # Heliboard replaces
    com.samsung.android.honeyboard

    # Fossify suite replaces
    com.samsung.android.calendar
    com.sec.android.app.camera
    com.sec.android.gallery3d
    com.samsung.android.video
    com.sec.android.app.myfiles
    com.samsung.android.app.clockpack

    # Fennec replaces
    com.sec.android.app.sbrowser
    com.android.chrome

    # HERE WeGo replaces
    com.google.android.apps.maps

    # NewPipe replaces
    com.google.android.youtube

    # Fossify Messages / Signal replace
    com.google.android.apps.messaging

    # Proton Mail replaces
    com.google.android.gm

    # Spotify replaces
    com.google.android.apps.youtube.music

    # Fossify Gallery replaces Samsung video player
    com.samsung.android.video

    # Facebook preloads
    com.facebook.appmanager
    com.facebook.katana
    com.facebook.services
    com.facebook.system

    # Other clear replacements
    com.microsoft.skydrive
    com.google.android.apps.tachyon
    com.google.android.apps.turbo
    com.google.android.apps.docs
    com.google.android.apps.bard
    com.google.android.apps.restore
    com.google.android.tts
    com.google.android.videos
    com.google.ar.core
    com.google.android.setupwizard
    com.google.android.onetimeinitializer
    com.google.android.partnersetup
    com.google.android.projection.gearhead
    com.google.android.apps.accessibility.voiceaccess
    com.google.audio.hearing.visualization.accessibility.scribe
    com.google.android.apps.carrier.carrierwifi
    com.samsung.android.spay
    com.samsung.android.spayfw
    com.samsung.android.scloud
    com.samsung.android.samsungpass
    com.samsung.android.samsungpassautofill
    com.samsung.android.mobileservice
    com.sec.android.app.samsungapps
    com.sec.android.app.shealth
    com.samsung.android.forest
    com.samsung.android.lool
    com.samsung.android.app.find
    com.samsung.android.oneconnect
    com.samsung.android.app.watchmanager
    com.samsung.android.app.watchmanagerstub
    com.samsung.android.aremoji
    com.samsung.android.aremojieditor
    com.sec.android.mimage.avatarstickers
    com.sec.android.mimage.photoretouching
    com.samsung.android.accessibility.talkback
    com.samsung.accessibility
    com.samsung.android.easysetup
    com.sec.android.app.SecSetupWizard
    com.sec.android.app.setupwizard
    com.sec.android.easyMover
    com.sec.android.easyMover.Agent
    com.samsung.android.smartswitchassistant
    com.samsung.android.kidsinstaller
    com.sec.android.app.kidshome
    com.samsung.android.game.gamehome
    com.samsung.android.app.notes
    com.hiya.star
    com.sec.android.app.wlantest
    com.sec.android.app.hwmoduletest
    com.sec.android.app.servicemodeapp
    com.sec.android.RilServiceModeApp
    com.sec.factory.camera
    com.sec.android.app.factorykeystring
    com.sec.android.app.personalization
    com.sec.android.app.quicktool
  )

  for pkg in "${PKGS[@]}"; do pm_uninstall "$pkg"; done
}
