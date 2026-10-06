#!/bin/bash
# usage: run_step.sh N  -> builds head v6 at STEP N into /tmp work blend, renders closeups + compare into design/.../head_v6/stepN
set -e; cd "$(dirname "$0")/../../../.."; N=$1; D=design/model_sheets/aruun/fidelity/head_v6/step$N; mkdir -p $D /tmp/claude-0/w
STEP=$N python3 tools/modeling/aruun/v6_head/build_head6.py /tmp/claude-0/w/s$N.blend 2>&1 | grep -E "saved|Error|Traceback" || true
python3 tools/modeling/aruun/v6_head/render6.py /tmp/claude-0/w/s$N.blend $D $RARGS 2>&1 | tail -1
python3 tools/modeling/aruun/v6_head/sidebyside.py $D
