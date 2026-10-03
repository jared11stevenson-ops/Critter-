#!/usr/bin/env bash
# Validate the project on Godot 4.7.2 (the target engine).
# Usage: tools/validate.sh [--compat]   (--compat also checks the old 4.3 floor; no longer required)
cd "$(dirname "$0")/.."
G47=/opt/godot/Godot_v4.7.2-stable_linux.x86_64
G43=/opt/godot/Godot_v4.3-stable_linux.x86_64
status=0
run() {
  local G=$1; local tag=$2
  echo "=== $tag: import ==="
  timeout 300 $G --headless --editor --quit --path . 2>&1 | grep -E "ERROR|SCRIPT ERROR|Parse Error|error\(" | grep -v -E "ALSA|audio driver|dummy driver|init_output_device" | head -40
  echo "=== $tag: load all ==="
  out=$(timeout 300 $G --headless --path . res://tools/qa/check_all.tscn 2>&1)
  echo "$out" | grep -E "\[CHECK\]|SCRIPT ERROR|Parse Error|ERROR|WARNING: .*gd" | grep -v -E "ALSA|audio driver|dummy driver|init_output_device|Condition \"status < 0\"" | head -80
  echo "$out" | grep -q "failed=0" || status=1
}
run $G47 "Godot 4.7.2"
[ "$1" == "--compat" ] && run $G43 "Godot 4.3"
exit $status
