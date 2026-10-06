"""HEAD as the VISUAL HULL of the reference head silhouettes: voxel intersection of the extruded v2 completed SIDE mask (F,U) and BACK mask (L,U) over the head band,
smoothed, meshed with marching cubes. Constraints so the hull is a SKULL + slim muzzle, not winged: the back mask is clipped to the skull half-width around the head centre line
(tines/fringe come back as separate features), and the lateral half-width is tapered along F beyond the skull to a narrow wedge (the muzzle in the straight-on face is a narrow wedge).
Coordinates (F,U,L); head centre line L=HL.  Env: HULL_VOX (m, default 0.004)."""
import os, sys, numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../fidelity'))
os.environ.setdefault('FID_REF', 'v2')
import bpy
from scipy import ndimage as ndi
from skimage.measure import marching_cubes
import fid_common as fc
HL = 0.09
U0, U1 = 1.945, 2.135        # hull band: neck top .. crown (horns start above)
SK_HALF = float(os.environ.get('SK_HALF', '0.108'))              # skull half-width in L about HL (clips tines/fringe out of the hull)
F_SKULL = 0.06               # beyond this F the lateral half-width tapers to the muzzle wedge
MUZ_HALF_ROOT, MUZ_HALF_TIP, F_TIP = 0.085, 0.022, 0.20

def masks():
    # NOTE FID_REF must be v2 when this module is imported (set above before fid_common import by callers that import it first)
    s = fc.clean_mask(fc.load_ref_alpha('side')[..., 3]); b = fc.clean_mask(fc.load_ref_alpha('back')[..., 3])
    return s, b, fc.view_info('side')['axis_x_px'], fc.view_info('back')['axis_x_px']

def hull_field(vox=None):
    vox = vox or float(os.environ.get('HULL_VOX', '0.004'))
    s, b, axs, axb = masks()
    F = np.arange(-0.16, 0.24, vox); U = np.arange(U0, U1 + vox, vox); L = np.arange(HL - 0.20, HL + 0.20, vox)
    Fg, Ug, Lg = np.meshgrid(F, U, L, indexing='ij')
    # side mask lookup (col = axs + F*PPM, row = GROUND - U*PPM); back: image x = -L
    sc = np.clip(np.round(axs + Fg * fc.PPM).astype(int), 0, s.shape[1] - 1); sr = np.clip(np.round(fc.GROUND - Ug * fc.PPM).astype(int), 0, s.shape[0] - 1)
    bc = np.clip(np.round(axb - Lg * fc.PPM).astype(int), 0, b.shape[1] - 1)
    sil = s[sr, sc] & b[sr, bc]                                      # plain extruded-silhouette intersection (rectangular cross-sections)
    half = np.where(Fg <= F_SKULL, SK_HALF, np.clip(MUZ_HALF_ROOT + (MUZ_HALF_TIP - MUZ_HALF_ROOT) * (Fg - F_SKULL) / (F_TIP - F_SKULL), MUZ_HALF_TIP, MUZ_HALF_ROOT))
    sil &= np.abs(Lg - HL) <= half
    # SKULL part: replace the rectangular (F,L) cross-section of every height row by a super-ellipse with exactly the same F and L extents (silhouettes stay satisfied on both axes)
    n = float(os.environ.get('HULL_EXP', '2.6')); inside = np.zeros_like(sil)
    Fsk = F_SKULL + 0.015
    for k in range(len(U)):
        sk = sil[:, k, :] & (Fg[:, k, :] <= Fsk)
        if sk.sum() < 20: continue
        fi = np.nonzero(sk.any(1))[0]; li = np.nonzero(sk.any(0))[0]
        F0, F1, L0, L1 = F[fi[0]], F[fi[-1]], L[li[0]], L[li[-1]]
        a, bb = (F1 - F0) / 2 + vox, (L1 - L0) / 2 + vox; Fc, Lc = (F0 + F1) / 2, (L0 + L1) / 2
        t = float(np.clip((U[k] - U0) / 0.025, 0, 1)); t = t * t * (3 - 2 * t)          # blend the lowest rows into the neck cross-section (no hard seam)
        Fc, Lc, a, bb = (1 - t) * 0.005 + t * Fc, (1 - t) * 0.078 + t * Lc, (1 - t) * 0.056 + t * a, (1 - t) * 0.070 + t * bb
        e = (np.abs((Fg[:, k, :] - Fc) / a) ** n + np.abs((Lg[:, k, :] - Lc) / bb) ** n) <= 1.0
        inside[:, k, :] = e & sil[:, k, :] | (e & (Fg[:, k, :] <= Fsk) & sil[:, k, :])
    # MUZZLE part (beyond the skull): side silhouette x tapered wedge, with an elliptical (L,U) cross-section about the local vertical centre of the side mask
    mz = sil & (Fg > Fsk)
    inside |= mz
    return inside, (F, U, L), vox

def mesh_from_field(field, axes, vox, sigma=1.8, name='head_hull'):
    F, U, L = axes
    f = ndi.gaussian_filter(np.pad(field.astype(float), 2), sigma)
    verts, faces, _, _ = marching_cubes(f, 0.5)
    verts = verts - 2
    Fv = F[0] + verts[:, 0] * vox; Uv = U[0] + verts[:, 1] * vox; Lv = L[0] + verts[:, 2] * vox
    B = np.stack([Lv, -Fv, Uv], 1)               # (F,U,L) -> blender (L,-F,U)
    me = bpy.data.meshes.new(name); me.from_pydata(B.tolist(), [], faces.tolist()); me.update()
    ob = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(ob)
    for p in me.polygons: p.use_smooth = True
    return ob

JAW_PIVOT = (0.03, 2.03, HL)      # (F,U,L) jaw hinge
def jaw_mask(axes):
    """lower jaw = the hull slab below the mouth line (underside of the muzzle + the hooked beak). Mouth line: U < 2.045 for F > 0.05 (side silhouette: muzzle underside 2.01, beak 1.99-2.03)."""
    F, U, L = axes; Fg, Ug, Lg = np.meshgrid(F, U, L, indexing='ij')
    return (Fg > 0.05) & (Ug < 2.045)

def build_hull(parts, split_jaw=False):
    for o in list(parts):
        if o.name in ('cranium', 'snout'):
            parts.remove(o); bpy.data.objects.remove(o, do_unlink=True)
    field, axes, vox = hull_field()
    if not split_jaw:
        parts.append(mesh_from_field(field, axes, vox, name='skull_hull')); return
    jm = jaw_mask(axes)
    skull = field & ~jm
    jaw = field & ndi.binary_dilation(jm, iterations=0) & jm
    parts.append(mesh_from_field(skull, axes, vox, name='skull_hull'))
    jo = mesh_from_field(jaw, axes, vox, name='mandible')
    import mathutils
    pv = mathutils.Vector((JAW_PIVOT[2], -JAW_PIVOT[0], JAW_PIVOT[1]))            # origin = jaw pivot so the jaw can open
    for v in jo.data.vertices: v.co = v.co - pv
    jo.location = pv; parts.append(jo)


_SURF = None
def surface_offset(f, u, side):
    """lateral distance from the head centre line to the hull surface at (F=f, U=u) on `side` (+1 his left, -1 his right); 0.0 if outside the hull."""
    global _SURF
    if _SURF is None:
        field, (F, U, L), vox = hull_field(); _SURF = (F, U, L, field)
    F, U, L, field = _SURF
    i = int(np.clip(round((f - F[0]) / (F[1] - F[0])), 0, len(F) - 1)); j = int(np.clip(round((u - U[0]) / (U[1] - U[0])), 0, len(U) - 1))
    col = field[i, j, :]; idx = np.nonzero(col)[0]
    if len(idx) == 0: return 0.0
    return float((L[idx[-1]] - HL) if side > 0 else (HL - L[idx[0]]))
