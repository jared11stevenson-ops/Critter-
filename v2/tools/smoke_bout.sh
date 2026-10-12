#!/usr/bin/env bash
# Headless AI-vs-AI bouts for all seven critters (each as fighter A against the next in the roster), fails on any SCRIPT ERROR / unfinished bout.
# Rendered check with screenshots: tools/shoot_bout.sh 1280x720 --human --shot-at=1,3   /   tools/shoot_flow.sh (menus). Usage: smoke_bout.sh [profile]
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"; GODOT="${GODOT:-godot}"; PROF="${1:-standard}"
IDS=(aruun cigarra bramvex scarlith mollusk zephyr nyxaris pharilux); RC=0
for i in 0 1 2 3 4 5 6; do
  A=${IDS[$i]}; B=${IDS[$(( (i+1) % 7 ))]}
  OUT="$(timeout 120 "$GODOT" --headless --path "$HERE" res://src/arena/smoke_bout.tscn --fixed-fps 60 -- --a=$A --b=$B --profile=$PROF --speed=6 --max-sec=200 2>&1)"
  echo "$OUT" | grep SMOKE_RESULT
  if echo "$OUT" | grep -qE "SCRIPT ERROR|Parse Error" || ! echo "$OUT" | grep -q '"ended":true'; then echo "FAIL $A vs $B"; echo "$OUT" | grep -E "SCRIPT ERROR" -A3 | head; RC=1; fi
done
exit $RC
