#!/bin/bash
# usage: run_stage.sh STAGE OUTDIR   -> builds forms at STAGE, renders+compares against BOTH references (orig -> OUTDIR/orig, v2 -> OUTDIR/v2)
set -e
cd "$(dirname "$0")/../../../.."
S=$1; O=$2; mkdir -p $O
FORMS_STAGE=$S FORMS_OUT=$O python3 tools/modeling/aruun/v5_forms/build_forms.py 2>&1 | tail -1
for R in orig v2; do
  FID_REF=$R python3 tools/fidelity/render_model_views.py $O/forms.glb --out $O/$R/renders --keep-mace >/dev/null 2>&1
  FID_REF=$R python3 tools/fidelity/compare.py --render-dir $O/$R/renders --out $O/$R --views side back front 2>&1 | sed -n 7,8p | sed "s/^/[$R] /"
done
