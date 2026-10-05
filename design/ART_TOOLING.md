# ART_TOOLING - what this CPU sandbox can actually do for character art (Agent 4, 2026-10-05)

Box: 4 CPU cores, 15 GB RAM, no GPU. Outbound HTTPS to huggingface.co / pypi.org works (github.com only via git/pip).
Blender 5.0.1 as `bpy` module, torch 2.14 CPU, numpy/scipy/skimage/Pillow, rembg + Real-ESRGAN (already used for the sheets' hires/).

## Experiments (all timed, images in design/model_sheets/aruun/qa/)
| Tool | License | Result on CPU | Verdict |
|---|---|---|---|
| **TripoSR** (image -> 3D, 1.7 GB ckpt from HF `stabilityai/TripoSR`) | MIT | RUNS. torchmcubes replaced by a 10-line skimage shim, transformers pinned to 4.44.2. 24 s (back view) / 16 s (front view) per image, marching cubes res 192, ~3 GB RAM. Output `qa/tooling_triposr_test.png`: plausible lumpy figure with the right antler-horn silhouette, but noisy surface, proportions squashed, 3/4 front sheet gives a different pose than orthographic side/back. | Usable only as a loose volume prior; NOT sculpt-grade. Not used in the shipped mesh. |
| InstantMesh (Apache-2.0) | Apache | Not run: needs Zero123++ multi-view diffusion (~minutes per view on CPU) and 10+ GB of weights; TripoSR already showed single/multi-view LRM output is too soft for a hero. Listed as the next experiment if the creator supplies a GPU key. | untested |
| Hunyuan3D-2 | Tencent community licence (territory/size restrictions) | Excluded on licence. | no |
| SDXL-Turbo / SD-Turbo for texture passes | non-commercial research licence | Excluded on licence; SD 1.5 (OpenRAIL-M) would run (~20 s/step at 512 on 4 cores) but cannot keep sheet fidelity. | no |
| **xatlas** (UV atlas) | MIT | `pip install xatlas` works: 16k tris -> ~400 charts, packs in <2 s. Replaced Blender smart-project (which fragmented a decimated voxel mesh into 800 tiny islands). | USED |
| **scikit-image TV-L1 optical flow on silhouette SDFs** | BSD | Non-rigid fit of an existing mesh to the sheet's side+back silhouettes: IoU side 0.51 -> 0.90, back 0.67 -> 0.93 in 4 iterations, ~20 s. | USED (core of Aruun v2) |
| Voxel union + marching cubes (scipy/skimage) | BSD | Turns the (non-watertight, layered) legacy part shells into clean single-skin shells in 1 s each at 6 mm; per-slice 2D closing + fill closes open shells. | USED |
| Blender decimate / corrective smooth (bpy) | GPL tool, output ours | 130k-tri shell -> 5k tris in seconds. QuadriFlow also available headless (not needed yet). | USED |
| Blender Cycles CPU | | 500x800 clay/textured board in ~8 s at 24 spp: our review renderer. | USED |
| Sculpt brushes through bpy | | Brush operators need a 3D-view context; the voxel/SDF route (common/sdf2.py, shells.py) gives the same control headlessly. | not needed |
| Texture projection with visibility + PIL/numpy cleanup | | See pipeline below. Direct projection of a 3/4 painted view onto a different pose marbles; solved with confidence-gated, view-selected projection + palette quantisation + painted-class normal relief. | USED |

## Chosen pipeline ("sheet-fit rebuild", tools/modeling/aruun/v2/*, reusable for any cast member with side+back sheets)
1. `dump_old.py` legacy mesh/weights/parts -> npz (prior + skin donor).  2. `fit.py` SDF-flow warp of the prior to the sheet silhouettes.
3. `shells.py` voxel union -> clean single-skin shells (trunk+head, arms, legs) + head hull from sheet depth/width.
4. `horns.py`, `head_parts.py`, `cards.py` hand-authored pieces read off pixel picks of the sheet (tubes, cones, cloth cards).
5. `build_mesh.py` (bpy) decimate to budget -> `unwrap.py` (xatlas) -> `project.py` sheet projection (side/back/3-4 front registered by landmark rows),
   palette quantisation, grade, procedural paint for horns/cards, normal relief from painted plate classes, emissive/ORM.
6. `finish2.py` rig joints re-centred inside the new shells, nearest-vertex skin transfer from the legacy skin (smoothed, 4 influences),
   mocap animation retarget (tools/animation, unchanged), glb export (WebP, 2048). Same 36 bone names -> CharacterModel API untouched.
7. QA: `qa_board.py` (sheet | model), `qa_head.py`, `qa_turn.py`, Godot `_qa_pop.tscn` boards.

## What would need a GPU / hosted key (exact)
- Multi-view generation to fill the unseen front/inner surfaces (Zero123++ or SV3D): ~10-20 min per character per 6 views on this CPU; seconds on a GPU. Optional.
- A tuned image-to-3D (Hunyuan3D-2.1 class) for a true sculpt-grade base: not licence-compatible as is; InstantMesh would be the Apache route (GPU: ~1 min, CPU: untested, expected > 20 min).
Nothing in the current plan is blocked on a GPU.

---
## v3 learnings (Agent 4, face-first rebuild of both heroes) - what actually worked
1. **SDF-sculpted dedicated heads beat any projected/fitted head.** `tools/modeling/common/sdf2.py` (torch CPU) + marching cubes at 2-2.5 mm, smooth-union of
   ellipsoids/capsules, subtract for sockets/nostrils/mouth line, flat-cut planes for palate/tongue bed. ~45 s per head. Then Blender DECIMATE (collapse) to 2.5-3k tris
   (+ corrective smooth). Jaw / mandible is a separate SDF so it can be skinned to the existing `jaw` bone.
2. **Object-space painting (`common/texbake.py`)**: rasterise the final UV layout once -> per-texel world position + normal; every colour is a plain numpy function
   of (P, N, piece, param). Seams cannot show, regions are defined in 3D (sheet positions), line work is |signed distance| bands. xatlas only has to pack, never to be pretty.
   Bake 1.6 M texels in 3 s; a full 2048 paint is ~40 s.
3. **Texel budget by group, not by chart**: separate xatlas runs per group, composed into fixed rectangles (head 768 + 128 strip for eyes, body 1152, gear/horns 768-896).
   Eyes get a hand-made planar-disc UV (a 90-tri sphere split into 12 tiny charts lost its pupil in-engine).
4. **Per-vertex shader control in the glb (COLOR_0)**: r = inverted-hull outline width, g = rim strength, b = shade-floor boost. Thin geometry (hair, fringe, cords) and faces
   must not get the full outline: a 1.1 cm hull on a 2 cm hair tube is a black blob. Meshes without COLOR_0 are unaffected (Godot default white).
5. **Look at the ENGINE render, not only Cycles.** Three faults only showed in-engine: outline/rim swamping the face, mocap idle pitching the head at the sky, and inside-out
   hair tubes (cull_back + wrong winding = black). A numeric winding check (`face normal . (centroid - axis) > 0`) is a 5-line test; do it for every procedural tube.
6. Headless Blender 5 `export_scene.gltf` with shape keys + 20 sampled clips is slow (3-4 min); iterate on `prev_tex.py` (numpy z-buffer textured preview, 2 s) and export last.
7. The box is shared: load average 10-16 on 4 cores. Never `sleep`-poll; use blocking `timeout N bash -c 'until grep -q DONE log; do sleep 3; done'`.
8. Expressions: glTF morph targets (shape keys angry/calm/open on the head) + `CharacterModel.set_expression()` / automatic (angry while an action plays, open on hit*, calm when downed).
   Aruun additionally opens his real `jaw` bone in attack/hit/dash/rage clips (tools/animation/characters/aruun.py `jaw()`).

Pipelines: Aruun `tools/modeling/aruun/v3/run_all.sh`; Cigarra `tools/modeling/cigarra/v2/{head,body,cards}.py` -> `build_mesh2.py` -> `unwrap2.py` -> `paint2.py` -> `finish2.py`.
