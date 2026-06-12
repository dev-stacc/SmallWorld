#!/usr/bin/env bash
# modules/config/performance.sh — speed and battery optimisations

run_performance() {
  section "config/performance — animations"
  setting_global window_animation_scale    0
  setting_global transition_animation_scale 0
  setting_global animator_duration_scale   0

  section "config/performance — background processes"
  adb shell settings delete global max_background_processes >/dev/null && ok "max_background_processes=default"
  setting_global adaptive_battery_management_enabled 0
  setting_global app_standby_enabled       0

  section "config/performance — scanning"
  setting_global wifi_scan_always_enabled  0
  setting_global ble_scan_always_enabled   0

  section "config/performance — data"
  setting_global mobile_data_always_on     1

  section "config/performance — misc"
  setting_secure notification_history_enabled 0
  setting_secure send_action_app_error        0
  setting_system pointer_speed               7
  adb shell settings put global performance_mode_enabled 1 2>/dev/null \
    && ok "Samsung High Performance mode on" \
    || ok "performance_mode_enabled not supported (ok)"
}
