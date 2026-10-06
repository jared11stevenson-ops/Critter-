#!/bin/bash
# usage: measure.sh BLEND OUTDIR -> exports whole scene glb (context body+horns from P1b + v6 head), renders sil views, head-band IoU vs v2 + orig refs
set -e; cd "$(dirname "$0")/../../../.."; B=$1; O=$2; mkdir -p $O
python3 - "$B" "$O/forms.glb" <<'P' 2>&1 | grep -E "exported" || true
import sys, bpy
bpy.ops.wm.open_mainfile(filepath=sys.argv[1]); bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=sys.argv[2], export_format='GLB', use_selection=True); print('exported')
P
for R in v2 orig; do
  FID_REF=$R python3 tools/fidelity/render_model_views.py $O/forms.glb --out $O/$R/renders --keep-mace >/dev/null 2>&1
  FID_REF=$R python3 tools/modeling/aruun/v5_forms/band_iou.py $O/$R/renders $O/$R/band_iou.json 2>&1 | grep -E "^(head_|whole)" | sed "s/^/[$R] /"
done
