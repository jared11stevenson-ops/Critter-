#!/usr/bin/env bash
# Render screenshots of the game via Xvfb (Compatibility renderer, same as phones).
# Usage: tools/shot.sh <scene res path> <out prefix> <shots csv seconds> <quit seconds> [qa_script res path] [extra qa args...]
cd "$(dirname "$0")/.."
G=/opt/godot/Godot_v4.7.2-stable_linux.x86_64
SCENE=$1; OUT=$2; SHOTS=$3; QUIT=$4; SCRIPT=$5; shift 5 2>/dev/null
mkdir -p "$(dirname "$OUT")"
ARGS="qa qa_scene=$SCENE qa_out=$OUT qa_shots=$SHOTS qa_quit=$QUIT"
[ -n "$SCRIPT" ] && [ "$SCRIPT" != "-" ] && ARGS="$ARGS qa_script=$SCRIPT"
timeout $(( ${QUIT%.*} * 5 + 90 )) xvfb-run -a -s "-screen 0 1280x720x24" $G --path . --resolution 1280x720 -- $ARGS "$@" 2>&1 \
  | grep -v -E "ALSA|audio driver|dummy driver|init_output_device|Condition \"status < 0\"|^\s*at: |^$"
