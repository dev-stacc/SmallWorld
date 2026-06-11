#!/usr/bin/env bash
# modules/apps/default.sh — aggregator

run_apps() {
  header "apps"
  run_fdroid
  run_direct
  run_sideload
}
