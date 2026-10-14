# Tripo (image-to-3D) -> rig parts
Pipeline used for Aruun (v0.18):
1. `npx @gltf-transform/cli copy tools/source_art/aruun_tripo.glb /tmp/cu/tr/aruun_plain.glb`  (Tripo exports meshopt-compressed GLB; Blender cannot read it)
2. `python3 stage0_crop.py`   -> crop the single figure out of the sheet-shaped mesh
3. `python3 stage1_partition.py` -> assign every shard-island to a rig part (+ bridging so joints do not open); writes /tmp/cu/tr/mask.bin
4. `python3 stage2_build.py`  -> weld, decimate each part to its budget, scale, pivot, 2048 JPEG texture, export v2/art/models/aruun.glb + .json
The rig loads the model via RigBuilder.use_glb and the toon shader samples UV0 (use_tex). Landmarks/pole line in stage1 were measured off this one model.
For a new critter feed Tripo ONE clean character image (not a sheet) so the crop step is not needed.

## Cigarra (v0.20)
Source: tools/source_art/cigarra_tripo.glb (single clean figure, A-pose, faces -y). `npx @gltf-transform/cli copy` it to /tmp/cu/ci/cig_plain.glb, then `python3 tools/blender/tripo/tripo_build.py cigarra [debug]`.
Config lives in CONFIGS["cigarra"] (rotation to the lib frame, scale, pivots, partition rules incl. a capsule for her right arm, sockets). Her crown spheres stay in the head mesh (sidecar swarm_off: no procedural swarm); wings are the `extra` part; no weapon part.

## Mollusk (v0.21)
Source: tools/source_art/mollusk_tripo.glb (single figure, faces +x already, shell on his back = `extra`, mace/lantern = `weapon`). 4096 px texture (tex_size in CONFIGS). Decode with gltf-transform to /tmp/cu/mo/plain.glb, then `python3 tools/blender/tripo/tripo_build.py mollusk [debug]`.

## Bramvex (v0.22)
Source: tools/source_art/bramvex_tripo.glb (crouching hero pose; faces +y in the file, rotated -90 deg to +x; the file includes a ground slab that is dropped). His crouch overlaps arms/legs/cloak/club, so only four parts move: head, weapon (club), extra (bat wing + lantern pole); arms and legs are kept in the torso and the four unused rig parts are 1-triangle specks (targets = -1). `python3 tools/blender/tripo/tripo_build.py bramvex [debug]`.

## KNOWN ISSUE (open, parked by the creator): generated models lose face/detail in-game (Cigarra, Bramvex; Mollusk less so)
Creator report v0.20/v0.22: Cigarra's and Bramvex's faces and fine details are blurred/unreadable in the bout view; asks for at least 4K-level crispness. To fix LATER (ranked, cheapest first):
1. **Use the normal map.** Tripo ships NormalGL (4096) but the pipeline drops it (the new material keeps only base colour) and toon.gdshader ignores normals' fine detail (3 cel bands flatten it). Keep the normal texture through export, sample it in the shader (needs tangents) and let the cel bands see it.
2. **Proper high->low bake.** Cycles "selected to active" normal (+AO) bake from each part's high-poly mesh (200k-1M tris) onto its decimated mesh (same UVs). Real detail on 4-5k triangles.
3. **Spend triangles where the eye looks:** head 4.6k tris is too few for a face; give the head 8-12k and shrink the body/cloak; or split the face into its own island with its own budget.
4. **Texture:** use 4096 for every model (Cigarra is still 2048); skip the extra `tex_gain` wash (it flattens contrast) and thin the toon outline for textured models (px_width) so it stops eating detail.
5. **Camera:** bouts show the figure small; add face close-ups (intro stare-down, result screen) so the detail is seen.
Verify with a 1280x720 bout shot AND a phone-size (e.g. 720x360 crop) check of the face.

## Pharilux (prepared, not built: waiting for the creator's model)
Feed Tripo the STANDING front view (tools/source_art/for_3d/pharilux_turn_front.png), not the big hero crop (the hero is a seated/crouched pose: like Bramvex it would force a static body). If it still comes out crouched expect Bramvex-style parts (head / weapon / extra). Reminders: drop the ground slab (info["zmax"]), unused parts = -1 targets, give the head a bigger triangle budget, 4096 texture, tex_gain ~1.0, decode with `npx @gltf-transform/cli copy`. Draft rules are in `pharilux_part` / CONFIGS["pharilux"] in tripo_build.py (landmarks to be measured once the model exists: lantern helmet+antennae = head, wings = extra, chains/anchor = weapon).

## Pharilux (v0.23) - FIRST MODEL WITH THE DETAIL FIXES
`bake_normals=True` in CONFIGS: each part's welded full-resolution mesh is baked (Cycles, selected-to-active, tangent space) onto its decimated copy into ONE 4096 normal atlas (same UV layout as the colour texture), exported as the glTF normal map with tangents; the sidecar sets `normal_map`, `tex_gain 1.0`, `outline_px 1.3`; rig_build.use_glb hands normal_tex/use_nrm/outline to the toon shader (NORMAL_MAP). Head 8.2k triangles. Result: porthole eye, brass rivets and chains stay readable. TODO (parked): retrofit Cigarra, Bramvex, Mollusk, Aruun the same way (re-run their configs with bake_normals=True, tex 4096, meta normal_map/tex_gain/outline_px). Source: tools/source_art/pharilux_tripo.glb; he faces -y in the file (rot_z=+90); lantern tower + helmet + upper back = head, wings/cloak = extra, side chains = weapon, scythe arms + legs split.

## Nyxaris (v0.24) - built with the detail fixes (bake_normals)
Source: tools/source_art/nyxaris_tripo.glb (faces +x already; crab-spider). Parts: head = face + antenna arcs/bulbs + front crystal crest (8k tris), front feathery pincers = arm_f/arm_b, side legs split by side, rear abdomen + rear crystals = extra (sways), thorax = torso; no weapon (targets -1; sockets point at arm_f). `python3 tools/blender/tripo/tripo_build.py nyxaris [debug]` (needs /tmp/cu/nx/plain.glb from gltf-transform).

## Zephyr (v0.25) - built with the detail fixes (bake_normals)
Source: tools/source_art/zephyr_tripo.glb (standing, faces +x). Head = beak + flower crown + antenna twig (z>=0.80), moth wings + back cloak = extra, arms by side, legs by side, no weapon. He hovers in-game (rig cfg), so the feet float above the shadow. Known: a few dark holes on the back cloak where faces fell between parts.

## Scarlith (v0.26) - built with the detail fixes; LAST of the eight
Source: tools/source_art/scarlith_tripo.glb (faces +x). Head = tricorn + face + hat lantern (x>0.02, 0.50<=z<0.80), cheese carapace + rope + treasure chest = extra, hooked polearm = weapon, arms/legs split by side, coat/body = torso. All eight critters are now generated models; Aruun, Cigarra, Bramvex and Mollusk predate bake_normals and still need the retrofit (see KNOWN ISSUE above).

## Retrofit done (v0.27): Aruun, Cigarra, Mollusk, Bramvex rebuilt with bake_normals
All eight critters now use the high->low normal bake, 4096 textures, 7.6-8.2k triangle heads, tex_gain 1.0, outline_px 1.3. Aruun now has a CONFIGS entry (aruun_part, source /tmp/cu/tr/aruun_crop.glb from stage0_crop.py); the old stage1/2 scripts are kept for reference. Memory note: run at most TWO builds at once (a 1M-triangle torso bake killed a third parallel run).
