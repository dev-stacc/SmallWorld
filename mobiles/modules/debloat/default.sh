#!/usr/bin/env bash
# modules/debloat/default.sh — aggregator (mirrors default.nix imports pattern)

run_debloat() {
  header "debloat"
  run_nuclear
  run_replaced
  run_google
}
