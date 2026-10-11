#!/usr/bin/env bash
# Rendered (xvfb) AI or scripted-human bout with screenshots. Usage: shoot_bout.sh WxH [extra smoke args...]
# Shots go to v2/tools/qa/shots (git-ignored by .gitignore rule below). Needs xvfb-run; GODOT env overrides the binary.
set -u
RES="${1:-1280x720}"; shift || true
HERE="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
mkdir -p "$HERE/tools/qa/shots"
MESA_SHADER_CACHE_DISABLE=true CRITTER_TOUCH=1 xvfb-run -a -s "-screen 0 ${RES}x24" "$GODOT" --path "$HERE" --rendering-driver opengl3 --resolution "$RES" \
  res://src/arena/smoke_bout.tscn -- --shots="$HERE/tools/qa/shots" --touch "$@"
rm -rf "$HOME/.local/share/godot/app_userdata/CRITTER 2/shader_cache"   # regenerable and large (30 MB per run); the disk is tight
