#!/usr/bin/env bash
# Usage: v2/tools/sim/run_tournament.sh [N=200] [seed=1] [shards=4]   (run from anywhere)
set -e
GODOT="${GODOT:-/opt/godot/Godot_v4.7.2-stable_linux.x86_64}"
HERE="$(cd "$(dirname "$0")/../.." && pwd)"
N="${1:-200}"; SEED="${2:-1}"; SH="${3:-4}"
rm -f "$HERE"/tools/out/part_*.json
for ((i=0;i<SH;i++)); do
  "$GODOT" --headless --path "$HERE" -s res://tools/sim/tournament.gd -- "$N" "$SEED" "shard=$i/$SH" > "$HERE/tools/out/shard_$i.log" 2>&1 &
done
wait
"$GODOT" --headless --path "$HERE" -s res://tools/sim/tournament.gd -- "$N" "$SEED" merge
