"""Blender reference-plane importer for a CRITTER reference pack (Blender 4.x/5.x, GUI or headless).

  blender --python tools/refsheets/blender_refplanes.py -- design/reference_packs/aruun [--mesh] [--opacity 0.7] [--save out.blend]

Reads <pack>/metadata.json (written by tools/refsheets/ortho.py) and builds, at TRUE SCALE (1 BU = 1 m, character origin = point on the ground under the
body centre line, character faces -Y like Blender's default front view, +Z up):
  REF_front  seen from -Y (numpad 1)         placed behind the figure at +Y
  REF_side   seen from -X (ctrl+numpad 3)    figure faces screen-right; placed at -X
  REF_back   seen from +Y (ctrl+numpad 1)    placed at -Y
All views share the same pixel scale and landmark rows, so a vertex placed on 'eyes' in the front plane is on 'eyes' in the side plane.
Default objects are Image Empties (only visible when looking straight at them, hidden from behind, alpha-aware - ideal for modelling);
--mesh makes textured plane meshes instead. A REF_landmarks collection holds one named horizontal edge per landmark (crown, eyes, chin, shoulder, ...)
at its canonical height so you can snap to it.
"""
import sys, os, json, math

try:
    import bpy
except ImportError:
    sys.exit("run inside Blender: blender --python blender_refplanes.py -- <pack_dir> [--mesh]")


def parse():
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    pack = next((x for x in a if not x.startswith("--")), None)
    opts = dict(mesh="--mesh" in a, opacity=0.75, save=None)
    if "--opacity" in a: opts["opacity"] = float(a[a.index("--opacity") + 1])
    if "--save" in a: opts["save"] = a[a.index("--save") + 1]
    return pack, opts


# per view: rotation (euler), unit vectors of image-right and image-up in world, plane-normal, and the sign of the depth offset
VIEWS = {
    "front": dict(rot=(math.pi / 2, 0, 0), right=(1, 0, 0), depth=(0, 1, 0)),
    "side":  dict(rot=(math.pi / 2, 0, -math.pi / 2), right=(0, -1, 0), depth=(-1, 0, 0)),
    "back":  dict(rot=(math.pi / 2, 0, math.pi), right=(-1, 0, 0), depth=(0, -1, 0)),
}


def build(pack, opts):
    meta = json.load(open(os.path.join(pack, "metadata.json")))
    ppm = meta["px_per_m"]; H_px = meta["canvas_h"]; gy = meta["ground_y"]
    col = bpy.data.collections.new("REF_" + meta["id"]); bpy.context.scene.collection.children.link(col)
    widths = [v["width_px"] / ppm for v in meta["views"].values()]
    D = 0.5 * max(widths) + 0.4                                     # distance of each plane from the origin (clears the body)
    for name, v in meta["views"].items():
        if name not in VIEWS or not v.get("aligned", True): continue                              # 3/4 views (if any) are for looking at, not for snapping
        cfg = VIEWS[name]; img = bpy.data.images.load(os.path.join(pack, v["file"])); img.name = f'{meta["id"]}_{name}'
        w_m, h_m = v["width_px"] / ppm, H_px / ppm
        up = (0, 0, 1); r = cfg["right"]
        # lower-left corner of the picture relative to the origin: image x=axis_x is on the body centre line, image y=ground_y is the ground
        c0 = [-r[i] * v["axis_x_px"] / ppm for i in range(3)]; z0 = -(H_px - gy) / ppm
        loc = (c0[0] + cfg["depth"][0] * D, c0[1] + cfg["depth"][1] * D, z0)
        if opts["mesh"]:
            me = bpy.data.meshes.new(f"REF_{name}")
            pts = []
            for (u, vv) in ((0, 0), (w_m, 0), (w_m, h_m), (0, h_m)):
                pts.append(tuple(loc[i] + r[i] * u + up[i] * vv for i in range(3)))
            me.from_pydata(pts, [], [(0, 1, 2, 3)]); me.update()
            uv = me.uv_layers.new(name="UV")
            for l, p in zip(me.loops, ((0, 0), (1, 0), (1, 1), (0, 1))): uv.data[l.index].uv = p
            ob = bpy.data.objects.new(f"REF_{name}", me); mat = bpy.data.materials.new(f"REF_{name}"); mat.use_nodes = True
            nt = mat.node_tree; nt.nodes.clear(); t = nt.nodes.new("ShaderNodeTexImage"); t.image = img
            em = nt.nodes.new("ShaderNodeBsdfTransparent"); mix = nt.nodes.new("ShaderNodeMixShader"); sh = nt.nodes.new("ShaderNodeEmission"); out = nt.nodes.new("ShaderNodeOutputMaterial")
            nt.links.new(t.outputs["Color"], sh.inputs["Color"]); nt.links.new(t.outputs["Alpha"], mix.inputs["Fac"]); nt.links.new(em.outputs[0], mix.inputs[1]); nt.links.new(sh.outputs[0], mix.inputs[2]); nt.links.new(mix.outputs[0], out.inputs["Surface"])
            mat.blend_method = "BLEND" if hasattr(mat, "blend_method") else None
            me.materials.append(mat)
        else:
            ob = bpy.data.objects.new(f"REF_{name}", None); ob.empty_display_type = "IMAGE"; ob.data = img
            ob.empty_display_size = max(w_m, h_m)                    # longest side of the image in metres
            sx = 1.0                                                  # image empty origin = lower-left corner when offset is (0,0)
            ob.empty_image_offset = (0.0, 0.0)
            ob.use_empty_image_alpha = True; ob.color = (1, 1, 1, opts["opacity"])
            ob.show_empty_image_perspective = False; ob.show_empty_image_orthographic = True; ob.show_empty_image_only_axis_aligned = True
            ob.empty_image_side = "FRONT"
            ob.location = loc; ob.rotation_euler = cfg["rot"]
        ob.rotation_euler = cfg["rot"]
        if opts["mesh"]: ob.location = (0, 0, 0); ob.rotation_euler = (0, 0, 0)
        col.objects.link(ob)
        ob["px_per_m"] = ppm; ob["axis_x_px"] = v["axis_x_px"]; ob["source_pose"] = v["pose"]; ob["orthographic"] = v["orthographic"]
    lm = bpy.data.collections.new("REF_landmarks"); bpy.context.scene.collection.children.link(lm)
    for k, z in meta["landmarks_m"].items():
        me = bpy.data.meshes.new("LM_" + k); me.from_pydata([(-0.9, 0, z), (0.9, 0, z)], [(0, 1)], []); ob = bpy.data.objects.new("LM_" + k, me)
        ob.display_type = "WIRE"; ob.show_in_front = True; lm.objects.link(ob); ob["height_m"] = z
    sc = bpy.context.scene; sc.unit_settings.system = "METRIC"; sc.unit_settings.scale_length = 1.0
    return meta


if __name__ == "__main__":
    pack, opts = parse()
    if not pack: sys.exit("usage: blender --python blender_refplanes.py -- <pack_dir> [--mesh] [--opacity 0.7] [--save out.blend]")
    meta = build(os.path.abspath(pack), opts)
    print("REF planes built for", meta["id"], "px_per_m", meta["px_per_m"])
    if opts["save"]: bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(opts["save"]))
