#!/usr/bin/env bash
# modules/config/default.sh — aggregator

run_config() {
  header "config"
  run_device
  run_privacy
  run_performance
  run_permissions
}
