#!/usr/bin/env bash
# Aruun v3 full rebuild (head -> horns -> mesh -> uv -> paint -> rig/glb). Needs work/v2 (shells_hi, cards, fit, old).
set -e
cd "$(dirname "$0")/.."
python3 v3/head.py && python3 v3/horns3.py && python3 v3/build_mesh3.py | tail -3 && python3 v3/unwrap3.py | tail -1 && python3 v3/paint3.py | tail -1
python3 v3/finish3.py ${1:-} | tail -3
