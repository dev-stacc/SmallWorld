#!/usr/bin/env bash
# modules/config/device.sh — device identity

run_device() {
  section "config/device"
  adb shell settings put global device_name       "$DEVICE_NAME"      && ok "device_name=$DEVICE_NAME"
  adb shell settings put secure bluetooth_name    "$DEVICE_BLUETOOTH_NAME" && ok "bluetooth_name=$DEVICE_BLUETOOTH_NAME"
}
