"""Orthographic reference cameras (side/back/front) exactly as tools/fidelity/render_model_views.py defines them (reference window, no pad)."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from camlib import *
META = json.load(open(os.path.join(ROOT, 'design/reference_packs/aruun/metadata.json')))
PPM, GROUND = META['px_per_m'], META['ground_y']
def ortho(view):
    v = META['views'][view]; ax = v['axis_x_px']
    Rm = {'side': [[0, 0, 1], [0, -1, 0], [1, 0, 0]],      # camera at his right looking +X ; image-right = forward (+Z)
          'back': [[-1, 0, 0], [0, -1, 0], [0, 0, 1]],     # camera behind looking +Z ; image-right = his right (-X)
          'front': [[1, 0, 0], [0, -1, 0], [0, 0, -1]]}[view]
    return Cam([0, 0, 0], Rm, 1, ax, GROUND, v['width_px'], 4096, ortho_scale=PPM, name=view)
