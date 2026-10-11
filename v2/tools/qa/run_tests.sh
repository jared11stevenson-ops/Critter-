#!/usr/bin/env bash
# Runs the v2 test suite. Usage: v2/tools/qa/run_tests.sh [filter]   (env GODOT=path to the godot binary)
# Fails (exit 1) if the runner fails OR the engine logged any SCRIPT ERROR / Parse Error: a runtime error inside a
# typed `func run() -> Array` yields an empty (passing) array, so the log must be checked too.
set -u
GODOT="${GODOT:-godot}"
HERE="$(cd "$(dirname "$0")/../.." && pwd)"
"$GODOT" --headless --path "$HERE" --import >/dev/null 2>&1
LOG="$(mktemp)"
if [ $# -gt 0 ]; then
  "$GODOT" --headless --path "$HERE" -s res://tools/qa/run_tests.gd -- "$1" 2>&1 | tee "$LOG"
else
  "$GODOT" --headless --path "$HERE" -s res://tools/qa/run_tests.gd 2>&1 | tee "$LOG"
fi
RC=${PIPESTATUS[0]}
if grep -qE "SCRIPT ERROR|Parse Error|Failed to load script" "$LOG"; then
  echo "run_tests.sh: script errors found in the log" >&2
  RC=1
fi
rm -f "$LOG"
exit "$RC"
