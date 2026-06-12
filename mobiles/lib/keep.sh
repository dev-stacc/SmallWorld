#!/usr/bin/env bash
# lib/keep.sh — packages the system needs to function. uninstalling any of
# these triggers crashes, bootloops, or rescue-party safe-mode lockouts.

KEEP=(
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

  # FCM — minimum Google footprint for push
  com.google.android.gms
  com.google.android.gsf

  # WebView — system-wide runtime; removing it bootloops the device
  com.google.android.webview

  # Mainline modules — infrastructure, not bloat
  com.google.android.providers.media.module
  com.google.android.modulemetadata

  # NFC — system_server uses com.android.nfc package context
  com.android.nfc

  # systemui plugin hosts — face widget / battery stats receivers crash without these
  com.samsung.android.app.clockpack
  com.sec.android.sdhms

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
