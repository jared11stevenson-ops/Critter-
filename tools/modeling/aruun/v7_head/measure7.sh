#!/bin/bash
# usage: measure7.sh HEAD7.blend OUTDIR -> band IoU of the whole scene with head v7 swapped into LOCKED_P1d, vs v2 and orig refs
set -e; cd "$(dirname "$0")/../../../.."; B=$1; O=$2; mkdir -p $O
python3 tools/modeling/aruun/v7_head/assemble7.py $B $O/scene.blend 2>&1 | grep -E "assembled|rror" || true
python3 - "$O/scene.blend" "$O/forms.glb" <<'P' 2>&1 | grep -E "exported" || true
import sys, bpy
bpy.ops.wm.open_mainfile(filepath=sys.argv[1]); bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=sys.argv[2], export_format='GLB', use_selection=True); print('exported')
P
for R in v2 orig; do
  FID_REF=$R python3 tools/fidelity/render_model_views.py $O/forms.glb --out $O/$R/renders --keep-mace >/dev/null 2>&1
  FID_REF=$R python3 tools/modeling/aruun/v5_forms/band_iou.py $O/$R/renders $O/$R/band_iou.json 2>&1 | grep -E "^(head_|whole)" | sed "s/^/[$R] /"
done
