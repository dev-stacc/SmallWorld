#!/usr/bin/env bash
# modules/debloat/nuclear.sh

run_nuclear() {
  declare -A KEEP_SET
  for pkg in "${KEEP[@]}"; do KEEP_SET[$pkg]=1; done

  section "debloat/nuclear — disabling system packages"
  local ENABLED OK=0 SKIP=0 FAIL=()
  ENABLED=$(adb shell pm list packages --user 0 | sed 's/package://' | tr -d '\r')

  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    if [[ -n "${KEEP_SET[$pkg]:-}" ]]; then SKIP=$((SKIP+1)); continue; fi
    local result
    result=$(adb shell pm disable-user --user 0 "$pkg" </dev/null 2>&1) || true
    if echo "$result" | grep -q "new state: disabled"; then
      ok "$pkg"; OK=$((OK+1))
    else
      echo "??   $pkg  ($result)"; FAIL+=("$pkg")
    fi
  done <<< "$ENABLED"

  echo ""
  echo "Disabled: $OK  |  Kept: $SKIP  |  Failed: ${#FAIL[@]}"
  for f in "${FAIL[@]}"; do fail "$f"; done

  section "debloat/nuclear — uninstalling user apps"
  local USER_APPS U_OK=0 U_FAIL=()
  USER_APPS=$(adb shell pm list packages -3 --user 0 | sed 's/package://' | tr -d '\r')

  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    local result
    result=$(adb shell pm uninstall -k --user 0 "$pkg" </dev/null 2>&1) || true
    if echo "$result" | grep -q "Success"; then
      ok "$pkg"; U_OK=$((U_OK+1))
    else
      echo "??   $pkg  ($result)"; U_FAIL+=("$pkg")
    fi
  done <<< "$USER_APPS"

  echo ""
  echo "Uninstalled: $U_OK  |  Failed: ${#U_FAIL[@]}"
  for f in "${U_FAIL[@]}"; do fail "$f"; done
}
