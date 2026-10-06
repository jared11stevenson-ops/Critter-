#!/bin/bash
# usage: iter.sh TAG [views] -> build + render + overlay into design/.../head_v7/TAG
set -e; cd "$(dirname "$0")/../../../.."; T=$1; V=${2:-side,front,back}; D=design/model_sheets/aruun/fidelity/head_v7/$T; mkdir -p $D /tmp/claude-0/w
python3 tools/modeling/aruun/v7_head/build_head7.py /tmp/claude-0/w/$T.blend 2>&1 | grep -E "^saved|Error|error:|line [0-9]+, in" || true
python3 tools/modeling/aruun/v7_head/render7.py /tmp/claude-0/w/$T.blend $D --only $V 2>&1 | grep -E "rror:|Traceback" || true
python3 tools/modeling/aruun/v7_head/post7.py $D $V
