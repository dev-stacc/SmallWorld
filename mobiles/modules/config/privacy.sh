#!/usr/bin/env bash
# modules/config/privacy.sh — privacy and tracking mitigations

run_privacy() {
  section "config/privacy — DNS"
  setting_global private_dns_mode     hostname
  setting_global private_dns_specifier dns.quad9.net

  section "config/privacy — captive portal (redirect away from Google)"
  setting_global captive_portal_https_url "https://detectportal.firefox.com/success.txt"
  setting_global captive_portal_http_url  "http://detectportal.firefox.com/success.txt"
  setting_global captive_portal_fallback_url "http://detectportal.firefox.com/success.txt"

  section "config/privacy — NTP"
  setting_global ntp_server pool.ntp.org

  section "config/privacy — backup"
  adb shell bmgr enable false               && ok "bmgr disabled"
  setting_secure backup_enabled 0

  section "config/privacy — A-GPS / SUPL"
  setting_secure assisted_gps_enabled 0

  section "config/privacy — lock screen"
  setting_secure lock_screen_show_notifications       0
  setting_secure lock_screen_allow_private_notifications 0

  section "config/privacy — clipboard access notifications"
  setting_secure clipboard_show_access_notifications 1

  section "config/privacy — USB default (charging only)"
  adb shell svc usb setFunctions charging 2>/dev/null && ok "usb=charging" || ok "usb setFunctions not available (ok)"
  setting_global default_usb_configuration charging
}
