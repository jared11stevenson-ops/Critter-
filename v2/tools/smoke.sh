#!/usr/bin/env bash
# Smoke bot skeleton: boots the v2 main scene headless for N seconds and fails on any script error.
# Usage: v2/tools/smoke.sh [seconds=10] [scene]      env GODOT=path to the godot binary
# Exit: 0 clean, 1 script errors found, 2 engine failed to start.
set -u
SECS="${1:-10}"
SCENE="${2:-}"
GODOT="${GODOT:-godot}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$(mktemp)"
"$GODOT" --headless --path "$HERE" --import >/dev/null 2>&1
ARGS=(--headless --path "$HERE")
[ -n "$SCENE" ] && ARGS+=("$SCENE")
timeout "$SECS" "$GODOT" "${ARGS[@]}" >"$LOG" 2>&1
RC=$?
# 124 = our timeout fired = the game ran the whole time (expected). Anything else means it quit or crashed early.
if [ "$RC" -ne 124 ] && [ "$RC" -ne 0 ]; then
  echo "smoke: engine exited early with code $RC"
  tail -n 30 "$LOG"
  [ "$RC" -ge 126 ] && exit 2
fi
if grep -nE "SCRIPT ERROR|Parse Error|Failed to load script|Compile Error" "$LOG"; then
  echo "smoke: FAILED (script errors above)"
  exit 1
fi

# TODO(QA): later smoke stages plug in here, each a script that drives the running game and returns non-zero on failure:
#   v2/tools/smoke/bout_bot.gd      boots a bout scene and plays N ticks with a scripted/AI input
#   v2/tools/smoke/touch_bot.gd     injects touch events into the touch controls and asserts the HUD reacts
# for hook in "$HERE"/tools/smoke/*.sh; do [ -x "$hook" ] && "$hook" "$GODOT" || exit 1; done

echo "smoke: OK (${SECS}s, no script errors)"
exit 0
