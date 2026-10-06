#!/usr/bin/env bash
# modules/debloat/google.sh

run_google() {
  section "debloat/google — uninstalling Google stack"
  local PKGS=(
    # GMS core — gms + gsf retained for FCM, see nuclear.sh KEEP
    com.google.android.gms.location.history
    com.google.android.gms.supervision

    # Search / Assistant / on-device ML
    com.google.android.googlequicksearchbox
    com.google.android.as
    com.google.android.as.oss

    # Advertising / tracking / personalization
    com.google.android.adservices.api
    com.google.mainline.adservices
    com.google.mainline.telemetry
    com.google.android.federatedcompute
    com.google.android.ondevicepersonalization.services

    # Feedback / config / device management
    com.google.android.feedback
    com.google.android.configupdater
    com.google.android.server.deviceconfig.resources
    com.google.android.rkpdapp
    com.google.android.verifier
    com.google.android.verifier.overlay

    # Health
    com.google.android.health.connect.backuprestore
    com.google.android.healthconnect.controller

    # Calendar sync / print
    com.google.android.syncadapters.calendar
    com.google.android.printservice.recommendation

    # Safety Center / setup / eSIM
    com.google.android.safetycenter.resources
    com.google.android.euicc
    com.google.android.captiveportallogin
    com.google.android.appsearch.apk

    # GMS config overlays
    com.google.android.overlay.gmsconfig.asi
    com.google.android.overlay.gmsconfig.common
    com.google.android.overlay.gmsconfig.geotz
    com.google.android.overlay.gmsconfig.gsa
    com.google.android.overlay.gmsconfig.photos

    # File / photo pickers — Fossify covers these
    com.google.android.documentsui
    com.google.android.photopicker

    # Text classifier / autofill hints — no replacement needed
    com.google.android.ext.services
    com.google.android.ext.shared

    # Module overlays (safe — base packages still active or also removed)
    com.google.android.overlay.modules.captiveportallogin.forframework
    com.google.android.overlay.modules.documentsui
    com.google.android.overlay.modules.ext.services
    com.google.android.overlay.modules.healthfitness.forframework
    com.google.android.overlay.modules.mediaprovider
    com.google.android.overlay.modules.modulemetadata.forframework
    com.google.android.overlay.modules.permissioncontroller
    com.google.android.overlay.modules.permissioncontroller.forframework
  )

  for pkg in "${PKGS[@]}"; do pm_uninstall "$pkg"; done
}
