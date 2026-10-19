# Skinned critter pipeline (Bramvex is the reference)

How a critter goes from a Tripo standing T-pose GLB to a fully animated fighter. Everything below exists and is tested for Bramvex; the next critters (Aruun first) repeat it.

## 1. Asset (tools/blender/rig/bramvex_skin.py, stages `prep` / `rig` / `final` / `diag`)
- Input: standing T-pose GLB (meshopt-compressed: decode with `npx @gltf-transform/cli copy`). Frame: faces +x, left = +y, feet z=0, game scale S=3.4.
- `prep`: decimate the ~1.9M-tri sculpt to ~55k tris (UV-delimited), save a low blend.
- `rig`/`final`: 31 hand-placed bones (hips, spine, chest, neck, head, shoulders, arm_up/lo, hands, thigh/shin/foot, wings, cloth chains cf/cb, club grips, antenna chains). Region weights + inverse-distance fallback, with SOFT BANDS wherever two rigid parts meet (arm/body, wing/arm, shoulder/head), then a normal bake from the full mesh and a skinned GLB export. The unused ORM texture is dropped on export.
- `diag`: poses the rig and lists triangles whose edges stretch >2.5x. Keep it near zero before exporting (Bramvex: 16 mild ones).
- Never trust a hard weight threshold: every stretched-triangle bug so far was a hard seam.

## 2. Rig in game (v2/src/critters/skinned_rig.gd, skin_poses.gd, skin_props.gd, shaders/toon.gdshader)
- `SkinnedRig.available(id)` loads and instantiates the GLB once; if anything is missing the fight falls back to the part rig (never an invisible fighter).
- Pose = {bone: Vector3(roll about X, pitch about Y, yaw about Z) degrees in the T-pose rest frame, "root": metres}. Yaw positive turns LEFT; hanging arm roll right +, left -; thigh pitch negative = forward; spine pitch positive = lean forward.
- Channels the bout scene feeds each frame (`fs`): action, action_frame, move_id, speed/fwd/side (gait, strafes, dodge direction; side positive = the critter's left), look (head yaw toward the foe), mood ("intro" salute, "won" victory), stun_kind (guardbreak / parried -> stagger variants).
- Poses exist for: idle (breathing, weight shift, wing twitch, glances), walk/run/backpedal/strafe, guard/parry, three attack styles (light, heavy, grab) + per-ability styles (ability1/2/3, laststand), directional dodge (back/forward/left/right), hit/stagger with sideways lean, guard-break, parried, knockdown/get-up, KO, intro salute, victory.
- Attacks use anticipation (slow in, tremble) / impact (overshoot + lunge) / recovery timed from the sim's frame data (Timing.resolve).
- Foot planting: a small Newton solve keeps ankles on the ground line (floor-only while walking so the swing foot lifts). Cost is ~0.2 ms/frame/fighter on the build box.
- Secondary motion: SpringBoneSimulator3D on cloth chains, wings and antenna chains (SPRINGS table). Props are procedural meshes with generated textures (tools/gen/gen_club_tex.py).
- Shader: normal-map texels that failed the bake (extreme tilt) fade to flat, otherwise they light as black wedges. Anisotropic sampling on.

## 3. QA tools
- `v2/tools/shoot_flow.sh WxH NAME --screen=skinsheet [--side] [--only=N | --from=N --count=M] [--rest] [--gait] [--live=<action>]`: pose sheet (states listed in skin_sheet.gd STATES).
- `v2/tools/shoot_bout.sh WxH --a=<id> --b=<id> --shot-at=...`: a real AI bout with screenshots + SMOKE_RESULT (draws, tris).
- v2/tools/qa/tests/test_skinned_rig.gd: bones, sockets, finite poses for every action and direction, anticipation/impact arc, victory/salute differ from idle, head look plumbing.
- Look at renders at 2000+ px and crop before judging; at bout scale most defects are invisible.

## 4. Open / not verified on device
Phone performance (Ultra tier = 1.5x supersample + 4x MSAA), Bramvex tris ~800k peak per bout incl. outline + shadow passes, real-bout left/right sign of strafes and head look-at.
