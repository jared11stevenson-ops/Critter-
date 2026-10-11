#!/usr/bin/env bash
# Screenshot of one menu / bout state through the real boot scene (xvfb, software GL).
# Usage: shoot_flow.sh WxH NAME [boot args...]      e.g.  shoot_flow.sh 1280x720 title --screen=title --shot-at=2
# Output: v2/tools/qa/shots/NAME_WxH.png  (not committed). Mesa/Godot shader caches are cleared afterwards (disk is tight).
set -u
RES="${1:-1280x720}"; NAME="${2:-shot}"; shift 2 || true
HERE="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
mkdir -p "$HERE/tools/qa/shots"
MESA_SHADER_CACHE_DISABLE=true CRITTER_TOUCH=1 timeout 170 xvfb-run -a -s "-screen 0 ${RES}x24" "$GODOT" --path "$HERE" --rendering-driver opengl3 --resolution "$RES" \
  -- --shot="$HERE/tools/qa/shots/${NAME}_${RES}.png" --touch "$@" 2>&1 | grep -E "SHOT|SCRIPT ERROR|Parse Error"
rm -rf "$HOME/.local/share/godot/app_userdata/CRITTER 2/shader_cache"
