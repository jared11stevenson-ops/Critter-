#!/usr/bin/env bash
# Package the project as CRITTER_vX.Y.Z.zip for import into the Godot mobile editor.
cd "$(dirname "$0")/.."
VER=$(grep -oP 'config/version="\K[^"]+' project.godot)
OUTDIR=${1:-/home/user/critter_builds}
mkdir -p "$OUTDIR"
NAME="CRITTER_v$VER"
rm -f "$OUTDIR/$NAME.zip"
# Exclude editor cache, git, tool outputs. Keep tools/qa (inert) so the project loads cleanly.
zip -q -r "$OUTDIR/$NAME.zip" . -x ".git/*" ".godot/*" "*.import.tmp" "tools/source_art/*" "design/*.docx" ".claude/*" "design/model_sheets/*" "design/qa/*" "tools/animation/mocap/*" "tools/animation/__pycache__/*" "*.pth" "*.onnx" "game/art/models/*/*_albedo.png*" "game/art/models/*/*_normal.png*" "game/art/models/*/*_orm.png*" "*/__pycache__/*" "*.pyc"
ls -la "$OUTDIR/$NAME.zip"
