#!/bin/bash
# Regenerates every sheet into design/v2/sheets (PNG, downscaled, total < 6 MB).
#   tools/make_all_sheets.sh [godot-binary]
# Needs xvfb-run + python3 with PIL. Software GL is fine (llvmpipe).
set -e
GODOT=${1:-/opt/godot/Godot_v4.7.2-stable_linux.x86_64}
HERE=$(cd "$(dirname "$0")" && pwd)
V2=$(cd "$HERE/../../.." && pwd)
OUT=$(cd "$V2/.." && pwd)/design/v2/sheets
TILES=${TMPDIR:-/tmp}/critter_tiles
rm -rf "$TILES"; mkdir -p "$TILES" "$OUT"
run() { (cd "$V2" && timeout 300 xvfb-run -a -s "-screen 0 1280x800x24" "$GODOT" --path . --rendering-driver opengl3 --script res://src/critters/tools/shoot.gd -- "$@" 2>&1 | grep -i "script error\|^error" || true); }
run --mode=turn --out="$TILES" --size=512
run --mode=actions --out="$TILES" --size=512
run --mode=expr --out="$TILES" --size=512
run --mode=lineup --out="$TILES" --size=560
run --mode=sil --out="$TILES" --size=256
run --mode=fx --ids=aruun,cigarra,nyxaris --out="$TILES" --size=512
python3 "$HERE/make_sheets.py" "$TILES" "$OUT" --tile=340
du -sh "$OUT"
