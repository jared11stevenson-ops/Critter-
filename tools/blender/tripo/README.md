# Tripo (image-to-3D) -> rig parts
Pipeline used for Aruun (v0.18):
1. `npx @gltf-transform/cli copy tools/source_art/aruun_tripo.glb /tmp/cu/tr/aruun_plain.glb`  (Tripo exports meshopt-compressed GLB; Blender cannot read it)
2. `python3 stage0_crop.py`   -> crop the single figure out of the sheet-shaped mesh
3. `python3 stage1_partition.py` -> assign every shard-island to a rig part (+ bridging so joints do not open); writes /tmp/cu/tr/mask.bin
4. `python3 stage2_build.py`  -> weld, decimate each part to its budget, scale, pivot, 2048 JPEG texture, export v2/art/models/aruun.glb + .json
The rig loads the model via RigBuilder.use_glb and the toon shader samples UV0 (use_tex). Landmarks/pole line in stage1 were measured off this one model.
For a new critter feed Tripo ONE clean character image (not a sheet) so the crop step is not needed.
