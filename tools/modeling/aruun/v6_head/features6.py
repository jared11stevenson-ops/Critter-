import os, numpy as np, bpy
from mathutils import Vector
import head6 as H
from head6 import HL, B
NAMES = []
def reg(ob, name): ob.name = name; ob.data.name = name; NAMES.append(name); return ob
def build(STEP):
    sk = reg(H.skull_loft(), 'skull')
    if STEP >= 1: pass
