#!/usr/bin/env bash
# Deterministic sequential frames of the animation QA stage + a contact sheet.
# Usage: tools/animation/qa_frames.sh <out_dir> <seq> <cam> <t0> <t1> <step> [cols] [crop WxH]
#   seq: loco|combo|abilities|react|walkcombo (game/art/models/_qa_anim.gd)   cam: game|close|close34|side|front
# Or any scene: QA_SCENE=res://... QA_EXTRA="qa_script=... qa_3d" tools/animation/qa_frames.sh ...
cd "$(dirname "$0")/../.."
OUT=$1; SEQ=$2; CAM=$3; T0=$4; T1=$5; STEP=$6; COLS=${7:-8}; CROP=${8:-}
G=/opt/godot/Godot_v4.7.2-stable_linux.x86_64
SCENE=${QA_SCENE:-res://game/art/models/_qa_anim.tscn}
mkdir -p "$OUT"
SHOTS=$(python3 -c "import numpy as np;print(','.join('%.3f'%t for t in np.arange($T0,$T1+1e-6,$STEP)))")
QUIT=$(python3 -c "print($T1+0.3)")
rm -f "$OUT"/f_*.png
timeout 600 xvfb-run -a -s "-screen 0 1280x720x24" $G --path . --resolution 1280x720 --fixed-fps 30 -- \
  qa qa_scene=$SCENE qa_out=$OUT/f qa_shots=$SHOTS qa_quit=$QUIT qa_seq=$SEQ qa_cam=$CAM $QA_EXTRA 2>&1 \
  | grep -E "SCRIPT ERROR|ERROR|Parse|\[QA\] quit" | head -20
python3 - "$OUT" "$T0" "$STEP" "$COLS" "$CROP" <<'PY'
import sys, glob
from PIL import Image, ImageDraw
out, t0, step, cols, crop = sys.argv[1], float(sys.argv[2]), float(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
fs = sorted(glob.glob(out + "/f_*.png"))
if not fs:
    sys.exit("no frames")
ims = []
for i, f in enumerate(fs):
    im = Image.open(f).convert("RGB")
    if crop:
        w, h = (int(x) for x in crop.split("x"))
        W, H = im.size
        im = im.crop(((W - w) // 2, (H - h) // 2, (W + w) // 2, (H + h) // 2))
    ImageDraw.Draw(im).text((6, 6), "%.2f" % (t0 + i * step), fill=(255, 255, 255))
    ims.append(im)
w, h = ims[0].size
s = min(1.0, 2400 / (w * cols))
tw, th = int(w * s), int(h * s)
rows = (len(ims) + cols - 1) // cols
sheet = Image.new("RGB", (tw * cols, th * rows), (0, 0, 0))
for i, im in enumerate(ims):
    sheet.paste(im.resize((tw, th)), ((i % cols) * tw, (i // cols) * th))
sheet.save(out + "/sheet.png")
print("sheet", out + "/sheet.png", len(ims), "frames")
PY
