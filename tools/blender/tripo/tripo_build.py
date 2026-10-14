"""Generic Tripo -> rig parts builder (used for Cigarra; Aruun's two-stage scripts predate it).
Usage: python3 tools/blender/tripo/tripo_build.py <critter> [debug]
  <critter> selects a config in CONFIGS below (source glb, orientation, scale, pivots, partition rules).
  "debug" only writes colour-coded partition renders to /tmp/cu/ci/dbg_*.png and stops (no export).
Frames: the source model is rotated into the lib frame (x = forward, y = across with the RIGHT hand at -y, z = up), then scaled so feet = 0."""
import bpy, bmesh, math, sys, json, os
from mathutils import Vector, Matrix
CID = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else (sys.argv[1] if len(sys.argv) > 1 else "cigarra")
DEBUG = "debug" in sys.argv
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "v2", "art", "models")
NAMES = ["torso", "head", "arm_f", "arm_b", "leg_f", "leg_b", "weapon", "extra"]

RIGHT_ARM = [(-0.03, -0.16, 0.65), (0.01, -0.18, 0.57), (0.07, -0.12, 0.52), (0.08, -0.12, 0.44)]

def _seg_dist(p, poly):
    best = 9.0
    for a, b in zip(poly, poly[1:]):
        ab = [b[i] - a[i] for i in range(3)]
        ap = [p[i] - a[i] for i in range(3)]
        t = max(0.0, min(1.0, sum(ab[i] * ap[i] for i in range(3)) / max(sum(v * v for v in ab), 1e-9)))
        d = math.sqrt(sum((ap[i] - ab[i] * t) ** 2 for i in range(3)))
        best = min(best, d)
    return best

def cigarra_part(c, el):
    """c = island centroid in the LIB frame BEFORE scaling (x fwd, y across [right = -y], z up, feet z=0, height 0.98)."""
    x, y, z = c
    if z >= 0.80 or (z >= 0.665 and abs(y) < 0.13 and x > -0.12):
        return "head"                                   # head, hair, crown spheres, hood collar
    if x < -0.035 and 0.07 < z < 0.70:
        return "extra"                                  # the wing-cloak behind her back
    if _seg_dist((x, y, z), RIGHT_ARM) < 0.075:
        return "arm_f"                                  # her right arm hangs forward with the hand at the belt: capsule around its measured path
    if abs(y) > 0.125 and z > 0.20:
        return "arm_f" if y < 0 else "arm_b"            # sleeves, hands, belt charms hanging at the sides (right hand = -y)
    if z < 0.50:
        return "leg_f" if y < 0 else "leg_b"
    return "torso"


def mollusk_part(c, el):
    """Mollusk (pre-scale, feet z=0, forward +x, right hand = -y): head+stalks on top, the great shell on his back (extra), mace/lantern at his right hand (weapon),
    arms outside the robe, legs under the robe, the rest (incl. the snail foot slab) is torso."""
    x, y, z = c
    if z >= 0.70 and x > -0.30 and (abs(y) < 0.17 or z >= 0.80):
        return "head"
    if y < -0.22 and z < 0.45 and x > -0.10:
        return "weapon"
    if x < -0.05 and z > 0.18:
        return "extra"
    if abs(y) > 0.13 and 0.30 < z < 0.74 and x > -0.10:
        return "arm_f" if y < 0 else "arm_b"
    if z < 0.38 and x > -0.05:
        return "leg_f" if y < 0 else "leg_b"
    return "torso"

def bramvex_part(c, info):
    """Bramvex (rotated so he faces +x; right hand = -y; feet z=0, height ~0.98). Crouching hero pose: only head, club, and the wing+lantern pole move; arms, legs and cloak stay in the torso."""
    x, y, z = c
    if info["zmax"] < 0.045:
        return "drop"                                   # the generator's ground slab
    if z >= 0.66 and abs(y) < 0.2:
        return "head"
    if y > 0.22 and z > 0.33:
        return "extra"                                  # the spread bat wing and the lantern pole (his left)
    if (x > 0.17 and z < 0.45) or (y < -0.22 and z < 0.35):
        return "weapon"                                 # the spiked club resting forward-right
    return "torso"

def pharilux_part(c, info):
    """Pharilux (rotated +90 so he faces +x; right = -y; feet z=0, lantern tip ~0.98). Mantis in a brass diver helmet with a lantern tower; wings and cloak behind; chains at his sides."""
    x, y, z = c
    if info["zmax"] < 0.045:
        return "drop"
    if z >= 0.62 and abs(y) < 0.22 and x > -0.20:
        return "head"                                   # insect head + helmet + lantern tower
    if x < -0.06 and 0.14 < z < 0.80:
        return "extra"                                  # wings and the cloak behind him
    if abs(y) > 0.24 and z < 0.62:
        return "weapon"                                 # the hanging chains / anchor at his sides
    if abs(y) > 0.13 and 0.30 < z < 0.66:
        return "arm_f" if y < 0 else "arm_b"            # scythe arms
    if z < 0.34:
        return "leg_f" if y < 0 else "leg_b"
    return "torso"

def nyxaris_part(c, info):
    """Nyxaris (faces +x already; right = -y; feet z=0, height ~0.98). Crab-spider: face+antennae+front crest = head, front feathery pincers = arms, side legs by side, rear abdomen + rear crystals = extra (sways), thorax = torso."""
    x, y, z = c
    if info["zmax"] < 0.045:
        return "drop"
    if (x > -0.05 and z >= 0.60) or (x > 0.20 and 0.40 <= z < 0.60 and abs(y) < 0.12):
        return "head"                                   # face (mandibles, fur), antenna arcs with the pink bulbs, front crystal crest
    if x < -0.12:
        return "extra"
    if x > 0.10 and abs(y) > 0.10 and 0.10 < z < 0.58:
        return "arm_f" if y < 0 else "arm_b"
    if z < 0.34 and abs(y) > 0.08:
        return "leg_f" if y < 0 else "leg_b"
    return "torso"

def zephyr_part(c, info):
    """Zephyr (faces +x already; right = -y; feet z=0, height ~0.98). Hummingbird-headed fairy: head + beak + flower crown + antenna twig = head, moth wings and back cloak = extra, arms at the sides, legs by side."""
    x, y, z = c
    if info["zmax"] < 0.045:
        return "drop"
    if z >= 0.80 or (x > 0.05 and z >= 0.70 and abs(y) < 0.10):
        return "head"
    if x < -0.02 and 0.10 < z < 0.80:
        return "extra"
    if abs(y) > 0.12 and 0.40 < z < 0.80:
        return "arm_f" if y < 0 else "arm_b"
    if z < 0.40:
        return "leg_f" if y < 0 else "leg_b"
    return "torso"

def scarlith_part(c, info):
    """Scarlith (faces +x; right = -y; feet z=0, height ~0.88). Pirate mite: tricorn + face (+ lantern at the hat) = head, cheese carapace + chest on his back = extra, grapple-hook polearm = weapon, furry arms and the eight legs split by side, coat/body = torso."""
    x, y, z = c
    if info["zmax"] < 0.045:
        return "drop"
    if x > 0.02 and 0.50 <= z < 0.80 and abs(y) < 0.30:
        return "head"
    if x < 0.02 and z > 0.30:
        return "extra"                                  # the big cheese carapace, rope and treasure chest
    if y < -0.20 and z < 0.55 and x > -0.1:
        return "weapon"                                 # the hooked polearm held in his right hand
    if abs(y) > 0.14 and 0.20 < z < 0.52:
        return "arm_f" if y < 0 else "arm_b"
    if z < 0.22:
        return "leg_f" if y < 0 else "leg_b"
    return "torso"

ARUUN_POLE = ((0.045, -0.175, 0.238), (-0.12, 0.005, 0.393))      # measured off the sheet-shaped source: where the mace handle runs behind his shoulder (feet-shifted frame)

def aruun_part(c, info):
    """Aruun (cropped from the Tripo sheet mesh; faces +x; right = -y; centre y=-0.08; feet shifted to z=0). Same rules as the old stage1 script, z + 0.158."""
    x, y, z = c
    dy = y + 0.08
    a = ARUUN_POLE[0]; b = ARUUN_POLE[1]
    ab = [b[i] - a[i] for i in range(3)]; L = math.sqrt(sum(v * v for v in ab)); d = [v / L for v in ab]
    v = [c[i] - a[i] for i in range(3)]; t = sum(v[i] * d[i] for i in range(3))
    if -0.02 < t < L + 0.03 and math.sqrt(max(0.0, sum(q * q for q in v) - t * t)) < 0.03:
        return "weapon"                                 # the mace handle that continues behind the shoulder
    if y < -0.205:
        return "weapon"                                 # the mace head and shaft out to his right
    if z >= 0.470 and abs(dy) < 0.13:
        return "head"
    if (z > 0.308 and x < 0.005) or (0.158 < z <= 0.308 and x < 0.025):
        return "extra"                                  # shell / cloak behind him
    if abs(dy) > 0.07 and z > 0.193:
        return "arm_f" if dy < 0 else "arm_b"
    if z < 0.293:
        return "leg_f" if dy < 0 else "leg_b"
    return "torso"

CONFIGS = {
    "aruun": dict(src="/tmp/cu/tr/aruun_crop.glb", rot_z=0.0, scale=7.0, x0=0.06, y0=-0.08, zfloor=-0.158, tex_size=4096, part=aruun_part, min_faces=0, bake_normals=True,
                  pivots={"torso": (0.06, -0.08, 0.308), "head": (0.08, -0.08, 0.468), "arm_f": (0.06, -0.165, 0.443), "arm_b": (0.06, 0.005, 0.443),
                          "leg_f": (0.06, -0.12, 0.293), "leg_b": (0.06, -0.04, 0.293), "weapon": (0.045, -0.175, 0.238), "extra": (0.0, -0.08, 0.438)},
                  targets={"torso": 3600, "head": 7600, "arm_f": 1900, "arm_b": 1900, "leg_f": 2200, "leg_b": 2200, "weapon": 2200, "extra": 2800},
                  sockets={"head": ("head", (0.1, 0.0, 0.05)), "hand": ("arm_f", (0.05, -0.02, -0.2)), "weapon_base": ("weapon", (0.0, 0.0, 0.1)), "weapon_tip": ("weapon", (0.162, -0.336 + 0.175, -0.081 - 0.08))},
                  meta={"textured": True, "face_off": True, "swarm_off": True, "tex_gain": 1.0, "outline_px": 1.3, "normal_map": True}),
    "scarlith": dict(src="/tmp/cu/sc/plain.glb", rot_z=0.0, scale=3.3, x0=-0.05, y0=0.0, tex_size=4096, part=scarlith_part, min_faces=0, bake_normals=True,
                    pivots={"torso": (0.0, 0.0, 0.32), "head": (0.12, 0.0, 0.52), "arm_f": (0.1, -0.2, 0.48), "arm_b": (0.1, 0.2, 0.48),
                            "leg_f": (0.0, -0.2, 0.25), "leg_b": (0.0, 0.2, 0.25), "weapon": (0.15, -0.3, 0.25), "extra": (-0.15, 0.0, 0.5)},
                    targets={"torso": 3600, "head": 7400, "arm_f": 1800, "arm_b": 1800, "leg_f": 2400, "leg_b": 2400, "weapon": 2000, "extra": 3200},
                    sockets={"head": ("head", (0.15, 0.0, 0.0)), "hand": ("arm_f", (0.05, 0.0, -0.2)), "weapon_base": ("weapon", (0.0, 0.0, 0.25)), "weapon_tip": ("weapon", (0.1, -0.2, -0.15))},
                    meta={"textured": True, "face_off": True, "swarm_off": True, "tex_gain": 1.0, "outline_px": 1.3, "normal_map": True}),
    "zephyr": dict(src="/tmp/cu/zp/plain.glb", rot_z=0.0, scale=3.2, x0=0.0, y0=0.0, tex_size=4096, part=zephyr_part, min_faces=0, bake_normals=True,
                    pivots={"torso": (0.0, 0.0, 0.52), "head": (0.0, 0.0, 0.80), "arm_f": (0.0, -0.13, 0.76), "arm_b": (0.0, 0.13, 0.76),
                            "leg_f": (0.0, -0.07, 0.50), "leg_b": (0.0, 0.07, 0.50), "weapon": (0.1, -0.2, 0.45), "extra": (-0.05, 0.0, 0.75)},
                    targets={"torso": 3600, "head": 7600, "arm_f": 2000, "arm_b": 2000, "leg_f": 2400, "leg_b": 2400, "weapon": -1, "extra": 3000},
                    sockets={"head": ("head", (0.1, 0.0, 0.05)), "hand": ("arm_f", (0.05, 0.0, -0.3)), "weapon_base": ("arm_f", (0.05, 0.0, -0.3)), "weapon_tip": ("arm_f", (0.2, 0.0, -0.3))},
                    meta={"textured": True, "face_off": True, "swarm_off": True, "tex_gain": 1.0, "outline_px": 1.3, "normal_map": True}),
    "nyxaris": dict(src="/tmp/cu/nx/plain.glb", rot_z=0.0, scale=3.0, x0=0.0, y0=0.0, tex_size=4096, part=nyxaris_part, min_faces=0, bake_normals=True,
                    pivots={"torso": (0.0, 0.0, 0.40), "head": (0.30, 0.0, 0.58), "arm_f": (0.20, -0.12, 0.42), "arm_b": (0.20, 0.12, 0.42),
                            "leg_f": (0.0, -0.15, 0.32), "leg_b": (0.0, 0.15, 0.32), "weapon": (0.3, 0.0, 0.4), "extra": (-0.12, 0.0, 0.45)},
                    targets={"torso": 3600, "head": 7600, "arm_f": 1900, "arm_b": 1900, "leg_f": 2400, "leg_b": 2400, "weapon": -1, "extra": 2800},
                    sockets={"head": ("head", (0.15, 0.0, 0.05)), "hand": ("arm_f", (0.1, 0.0, -0.2)), "weapon_base": ("arm_f", (0.1, 0.0, -0.2)), "weapon_tip": ("arm_f", (0.3, 0.0, -0.2))},
                    meta={"textured": True, "face_off": True, "swarm_off": True, "tex_gain": 1.0, "outline_px": 1.3, "normal_map": True}),
    "pharilux": dict(src="/tmp/cu/ph/plain.glb", rot_z=90.0, scale=3.6, x0=0.0, y0=0.0, tex_size=4096, part=pharilux_part, min_faces=0,
                    pivots={"torso": (0.0, 0.0, 0.42), "head": (0.05, 0.0, 0.72), "arm_f": (0.0, -0.16, 0.66), "arm_b": (0.0, 0.16, 0.66),
                            "leg_f": (0.0, -0.08, 0.42), "leg_b": (0.0, 0.08, 0.42), "weapon": (0.05, -0.25, 0.35), "extra": (-0.08, 0.0, 0.62)},
                    targets={"torso": 3600, "head": 8200, "arm_f": 1700, "arm_b": 1700, "leg_f": 2000, "leg_b": 2000, "weapon": 2000, "extra": 2600}, bake_normals=True,
                    sockets={"head": ("head", (0.1, 0.0, 0.1)), "hand": ("arm_f", (0.05, 0.0, -0.3)), "weapon_base": ("weapon", (0.0, 0.0, 0.2)), "weapon_tip": ("weapon", (0.1, 0.0, -0.2))},
                    meta={"textured": True, "face_off": True, "swarm_off": True, "tex_gain": 1.0, "tex_soft": 0.7, "outline_px": 1.3, "normal_map": True}),
    "bramvex": dict(src="/tmp/cu/br/plain.glb", rot_z=-90.0, scale=3.4, x0=0.0, y0=0.0, tex_size=4096, part=bramvex_part, min_faces=0, bake_normals=True,
                    pivots={"torso": (0.0, 0.0, 0.40), "head": (0.03, 0.0, 0.66), "arm_f": (0.0, -0.15, 0.58), "arm_b": (0.0, 0.15, 0.58),
                            "leg_f": (0.0, -0.08, 0.36), "leg_b": (0.0, 0.08, 0.36), "weapon": (0.12, -0.15, 0.30), "extra": (-0.05, 0.1, 0.55)},
                    targets={"torso": 8000, "head": 7600, "arm_f": -1, "arm_b": -1, "leg_f": -1, "leg_b": -1, "weapon": 3400, "extra": 3400},
                    sockets={"head": ("head", (0.08, 0.0, 0.08)), "hand": ("weapon", (0.0, 0.0, 0.1)), "weapon_base": ("weapon", (0.0, 0.0, 0.1)), "weapon_tip": ("weapon", (0.35, 0.0, -0.1))},
                    meta={"textured": True, "face_off": True, "swarm_off": True, "tex_gain": 1.0, "outline_px": 1.3, "normal_map": True}),
    "mollusk": dict(src="/tmp/cu/mo/plain.glb", rot_z=0.0, scale=3.4, x0=-0.05, y0=0.02, tex_size=4096, part=mollusk_part, min_faces=0, bake_normals=True,
                    pivots={"torso": (0.0, 0.0, 0.35), "head": (0.05, 0.0, 0.74), "arm_f": (0.0, -0.20, 0.66), "arm_b": (0.0, 0.22, 0.66),
                            "leg_f": (0.0, -0.10, 0.36), "leg_b": (0.0, 0.10, 0.36), "weapon": (0.02, -0.30, 0.30), "extra": (-0.12, 0.0, 0.50)},
                    targets={"torso": 3600, "head": 7600, "arm_f": 1900, "arm_b": 1900, "leg_f": 2200, "leg_b": 2200, "weapon": 2000, "extra": 3000},
                    sockets={"head": ("head", (0.1, 0.0, 0.1)), "hand": ("arm_f", (0.05, -0.08, -0.35)), "weapon_base": ("weapon", (0.0, 0.0, 0.2)), "weapon_tip": ("weapon", (0.1, -0.1, -0.2))},
                    meta={"textured": True, "face_off": True, "swarm_off": True, "tex_gain": 1.0, "outline_px": 1.3, "normal_map": True}),
    "cigarra": dict(src="/tmp/cu/ci/cig_plain.glb", rot_z=90.0, scale=3.3, x0=0.0, y0=0.0,
                    part=cigarra_part, min_faces=0, tex_size=4096, bake_normals=True,
                    pivots={"torso": (0.0, 0.0, 0.50), "head": (0.0, 0.0, 0.68), "arm_f": (0.0, -0.15, 0.66), "arm_b": (0.0, 0.15, 0.66),
                            "leg_f": (0.0, -0.07, 0.50), "leg_b": (0.0, 0.07, 0.50), "weapon": (0.0, -0.2, 0.3), "extra": (-0.06, 0.0, 0.68)},
                    targets={"torso": 3600, "head": 7600, "arm_f": 1900, "arm_b": 1900, "leg_f": 2400, "leg_b": 2400, "weapon": 0, "extra": 2800},
                    sockets={"head": ("head", (0.08, 0.0, 0.1)), "hand": ("arm_f", (0.0, 0.0, 0.25)), "weapon_base": ("arm_f", (0.0, 0.0, 0.25)), "weapon_tip": ("arm_f", (0.3, 0.0, 0.2)),
                             "crown": ("head", (0.0, 0.0, 0.22))},
                    meta={"textured": True, "face_off": True, "swarm_off": True, "tex_gain": 1.0, "outline_px": 1.3, "normal_map": True}),
}
C = CONFIGS[CID]
S = C["scale"]
rotm = Matrix.Rotation(math.radians(C["rot_z"]), 4, "Z")
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=C["src"])
src = [x for x in bpy.data.objects if x.type == "MESH"][0]
me = src.data
for v in me.vertices:
    v.co = (rotm @ (src.matrix_world @ v.co))
src.matrix_world = Matrix.Identity(4)
zmin = C.get("zfloor", min(v.co.z for v in me.vertices))
for v in me.vertices:
    v.co.z -= zmin
bm = bmesh.new(); bm.from_mesh(me); bm.faces.ensure_lookup_table()
seen = bytearray(len(bm.faces)); isl = []
for f in bm.faces:
    if seen[f.index]:
        continue
    st = [f]; seen[f.index] = 1; comp = []
    while st:
        cc = st.pop(); comp.append(cc)
        for e in cc.edges:
            for n in e.link_faces:
                if not seen[n.index]:
                    seen[n.index] = 1; st.append(n)
    isl.append(comp)
cents = []
for comp in isl:
    cs = Vector((0, 0, 0))
    for f in comp:
        cs += f.calc_center_median()
    cents.append(cs / len(comp))
mi = {n: i for i, n in enumerate(NAMES)}
def _isl_info(comp):
    zs = [v.co.z for f in comp for v in f.verts]
    return {"n": len(comp), "zmax": max(zs), "zmin": min(zs)}
infos = [_isl_info(comp) for comp in isl]
prim = [mi.get(C["part"]((cs.x, cs.y, cs.z), inf), -1) for comp, cs, inf in zip(isl, cents, infos)]   # "drop" -> -1 (island removed, e.g. the generator's ground slab)
# arms are mirror images in this A-pose: islands near the mirrored LEFT-arm islands (y > 0) that were swallowed by the trousers/torso become the RIGHT arm
if CID == "cigarra":
    left = [cents[k] for k in range(len(cents)) if prim[k] == mi["arm_b"]]
    for k, cs in enumerate(cents):
        if cs.y < -0.05 and cs.z > 0.20 and prim[k] in (mi["torso"], mi["leg_f"], mi["leg_b"]):
            m = Vector((cs.x, -cs.y, cs.z))
            if min((m - l).length for l in left) < 0.035:
                prim[k] = mi["arm_f"]
# bridging: neighbours within 0.012 (model units) share the island so rotating joints never open gaps
grid = {}
G = 0.012
for k, cs in enumerate(cents):
    grid.setdefault((int(cs.x // G), int(cs.y // G), int(cs.z // G)), []).append(k)
mask_isl = [(1 << p) if p >= 0 else 0 for p in prim]
for k, cs in enumerate(cents):
    gx, gy, gz = int(cs.x // G), int(cs.y // G), int(cs.z // G)
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                for j in grid.get((gx + dx, gy + dy, gz + dz), ()):
                    if prim[k] >= 0 and prim[j] >= 0 and prim[j] != prim[k] and (cents[j] - cs).length < G:
                        mask_isl[j] |= 1 << prim[k]
mask = bytearray(len(bm.faces))
for comp, m, p in zip(isl, mask_isl, prim):
    for f in comp:
        mask[f.index] = m
        f.material_index = 1 + max(p, 0)
print("faces per part", {n: sum(len(c) for c, m in zip(isl, mask_isl) if m >> mi[n] & 1) for n in NAMES}, "islands", len(isl))
if DEBUG:
    bm.to_mesh(me)
    cols = [(0.8, 0.8, 0.8), (1, 0.2, 0.2), (0.2, 0.9, 0.2), (0.2, 0.4, 1), (1, 0.9, 0.1), (0.9, 0.2, 0.9), (0.1, 0.9, 0.9), (1, 0.5, 0.1)]
    orig = me.materials[0]
    for n, c in zip(NAMES, cols):
        m = bpy.data.materials.new(n); m.use_nodes = True
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*c, 1); me.materials.append(m)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"; sc.cycles.samples = 8; sc.cycles.device = "CPU"
    sc.render.resolution_x = 600; sc.render.resolution_y = 800
    w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes["Background"].inputs[0].default_value = (0.6, 0.6, 0.65, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 1.2
    sun = bpy.data.objects.new("s", bpy.data.lights.new("s", "SUN")); sc.collection.objects.link(sun); sun.data.energy = 3; sun.rotation_euler = (math.radians(50), 0, math.radians(30))
    cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.type = "ORTHO"; cam.data.ortho_scale = 1.15
    for name, (loc, rot) in {"front": ((3, 0, 0.5), (90, 0, 90)), "side": ((0, 3, 0.5), (90, 0, 180)), "back": ((-3, 0, 0.5), (90, 0, -90)), "rside": ((0, -3, 0.5), (90, 0, 0))}.items():
        cam.location = loc; cam.rotation_euler = [math.radians(a) for a in rot]
        sc.render.filepath = f"/tmp/cu/ci/dbg_{name}.png"; bpy.ops.render.render(write_still=True)
    sys.exit(0)
srcmat = me.materials[0]
tex = None
for n in srcmat.node_tree.nodes:
    if n.type == "TEX_IMAGE" and n.image and ("BaseColor" in n.image.name or n.image.name.startswith("Color")):
        tex = n.image
print("colour texture", tex.name if tex else None, tex.size[:] if tex else None)
tex.scale(C.get("tex_size", 2048), C.get("tex_size", 2048))
mat = bpy.data.materials.new(CID + "_tex"); mat.use_nodes = True
nt = mat.node_tree; bsdf = nt.nodes["Principled BSDF"]
ti = nt.nodes.new("ShaderNodeTexImage"); ti.image = tex; nt.links.new(ti.outputs["Color"], bsdf.inputs["Base Color"]); bsdf.inputs["Roughness"].default_value = 0.9
def to_game(p):
    return Vector(((p[0] - C["x0"]) * S, (p[1] - C["y0"]) * S, p[2] * S))
objs = []
pairs = []
for i, name in enumerate(NAMES):
    if C["targets"].get(name, 0) == 0:
        continue
    if C["targets"].get(name, 0) < 0:      # unused rig part: a degenerate speck so the procedural placeholder is replaced by nothing visible
        pv = to_game(C["pivots"][name])
        m3 = bpy.data.meshes.new(name); m3.from_pydata([(0, 0, 0), (0.001, 0, 0), (0, 0.001, 0)], [], [(0, 1, 2)]); m3.materials.append(mat)
        ob3 = bpy.data.objects.new(name, m3); bpy.context.scene.collection.objects.link(ob3); ob3.location = pv
        continue
    b2 = bmesh.new(); b2.from_mesh(me); b2.faces.ensure_lookup_table()
    drop = [f for f in b2.faces if not (mask[f.index] >> i) & 1]
    bmesh.ops.delete(b2, geom=drop, context="FACES")
    bmesh.ops.remove_doubles(b2, verts=b2.verts, dist=0.0004)
    bmesh.ops.delete(b2, geom=[v for v in b2.verts if not v.link_faces], context="VERTS")
    pv = to_game(C["pivots"][name])
    for v in b2.verts:
        v.co = to_game(v.co) - pv
    m2 = bpy.data.meshes.new(name); b2.to_mesh(m2); b2.free()
    m2.materials.append(mat)
    ob = bpy.data.objects.new(name, m2); bpy.context.scene.collection.objects.link(ob)
    ob.location = pv
    bpy.context.view_layer.objects.active = ob; ob.select_set(True)
    bpy.ops.mesh.customdata_custom_splitnormals_clear(); bpy.ops.object.shade_smooth()
    t0 = sum(len(p.vertices) - 2 for p in m2.polygons)
    if C.get("bake_normals"):
        hi_me = m2.copy(); hi = bpy.data.objects.new(name + "_hi", hi_me); bpy.context.scene.collection.objects.link(hi); hi.location = pv
        bpy.context.view_layer.objects.active = hi; hi.select_set(True); bpy.ops.object.shade_smooth(); hi.select_set(False)
        bpy.context.view_layer.objects.active = ob
        pairs.append((hi, ob))
    mod = ob.modifiers.new("d", "DECIMATE"); mod.decimate_type = "COLLAPSE"; mod.ratio = min(1.0, C["targets"][name] / max(t0, 1)); mod.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier="d"); ob.select_set(False)
    objs.append(ob)
    print(name, "tris", t0, "->", sum(len(p.vertices) - 2 for p in ob.data.polygons))
bpy.data.objects.remove(src)
nrm_img = None
if pairs:
    # high -> low tangent-space normal bake: every part's full-resolution mesh paints its detail into ONE normal atlas that shares the colour UV layout
    N = C.get("nrm_size", 4096)
    nrm_img = bpy.data.images.new(CID + "_normal", N, N, alpha=False)
    nrm_img.generated_color = (0.5, 0.5, 1.0, 1.0)
    nrm_img.colorspace_settings.name = "Non-Color"
    bm_ = bpy.data.materials.new("bake"); bm_.use_nodes = True
    tn = bm_.node_tree.nodes.new("ShaderNodeTexImage"); tn.image = nrm_img; bm_.node_tree.nodes.active = tn
    sc_ = bpy.context.scene
    sc_.render.engine = "CYCLES"; sc_.cycles.device = "CPU"; sc_.cycles.samples = 1
    for hi, lo in pairs:
        lo.data.materials.clear(); lo.data.materials.append(bm_)
        bpy.ops.object.select_all(action="DESELECT"); hi.select_set(True); lo.select_set(True); bpy.context.view_layer.objects.active = lo
        bpy.ops.object.bake(type="NORMAL", use_selected_to_active=True, cage_extrusion=0.03, max_ray_distance=0.08, normal_space="TANGENT", margin=10, use_clear=False)
        print("baked", lo.name)
    for hi, lo in pairs:
        bpy.data.objects.remove(hi)
        lo.data.materials.clear(); lo.data.materials.append(mat)
    nn = mat.node_tree.nodes.new("ShaderNodeTexImage"); nn.image = nrm_img
    nm = mat.node_tree.nodes.new("ShaderNodeNormalMap")
    mat.node_tree.links.new(nn.outputs["Color"], nm.inputs["Color"]); mat.node_tree.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
os.makedirs(OUT, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, CID + ".glb"), export_format="GLB", use_selection=True, export_yup=True, export_apply=False,
                          export_materials="EXPORT", export_image_format="JPEG", export_jpeg_quality=90, export_tangents=bool(pairs), export_cameras=False, export_lights=False)
meta = dict(C["meta"])
meta["sockets"] = {k: [part] + [round(c, 4) for c in off] for k, (part, off) in C["sockets"].items()}
json.dump(meta, open(os.path.join(OUT, CID + ".json"), "w"), indent=1)
print("done", os.path.getsize(os.path.join(OUT, CID + ".glb")))
