#!/usr/bin/env bash
# modules/config/family.sh — set Lawnchair as default home

run_family() {
  section "config/family — Lawnchair as default home"
  adb shell cmd role add-role-holder android.app.role.HOME app.lawnchair 0 \
    && ok "home role → app.lawnchair"
}
