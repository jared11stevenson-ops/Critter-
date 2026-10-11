#!/usr/bin/env bash
# Package the v2 project as CRITTER2_vX.Y.Z.zip for import into the Godot mobile editor (project.godot at the zip root).
cd "$(dirname "$0")/../v2" || exit 1
VER=$(grep -oP 'config/version="\K[^"]+' project.godot)
OUTDIR=${1:-/home/user/critter_builds}
mkdir -p "$OUTDIR"
NAME="CRITTER2_v$VER"
rm -f "$OUTDIR/$NAME.zip"
zip -q -r "$OUTDIR/$NAME.zip" . -x ".godot/*" "*.import.tmp" "tools/out/*" "*/__pycache__/*" "*.pyc" "tools/qa/shots/*"
ls -la "$OUTDIR/$NAME.zip"
