# CRITTER — Changelog

Generated from the project's commit history (each line is a real committed change).
**[ART]** world/lighting/VFX · **[GAME]** gameplay, UI, performance · **[ANIM]** mocap animation + 3D models · **[CANON]** canon art fidelity · **[LEAD]** direction, canon, audio, text, integration

## v0.8.0 — Performance, motion capture, sharper characters (since v0.6.0)
- [GAME] Agent2 perf: billboard uniform diffing, off-screen creature anim skip, sky clouds off on Low, fallback suns follow quality, adaptive 3D render scale, slower-CPU-safe shot.sh timeout
- [GAME] Agent2 perf: Quality autoload (Low/Medium/High/Auto + 30/60 FPS), shader quality variants, chunked scatter, sky radiance fix, QA bench harness
- [ANIM] Agent4: animation SOURCES.md (every CMU clip + license), CMU credit, Aruun QA contact sheets (design/qa/agent4)
- [ANIM] Agent4: gameplay hits land on clip impact frames (attack_hit_time API + 3-line kit hook), channelled gravity_pull hold-to-slam, QA anim timing log + combat script
- [ANIM] Agent4: fix clip timing (bake at 30 fps from frame 0; glTF clips were 25% slow + held lead-in), phase loco loops to left stance; QA foot logging
- [ANIM] Agent4: merge master; add trimmed CMU 09_01 (heavy run source)
- [ANIM] Agent4: full Aruun mocap clip set (19 clips) via tools/animation/apply.py hook in finish.py; trimmed CMU sources
- [ANIM] Agent4: mocap retarget pipeline (BVH FK, rest-aligned retarget, foot-lock IK, Morrow pendulum) + first Aruun loco clips
- [CANON] Agent3: HD billboards back under budget (1.45x px): solmara 576, aruun/cigarra 512; feet kept on bottom edge
- [CANON] Agent3: HD zephyr (stray fragments removed), zephyr/solmara/scarlith/bramvex packs + specs, fragment cleanup, closeup QA scene
- [CANON] Agent3: HD scarlith billboard; Mara/Dexter spec.md
- [CANON] Agent3: HD billboards solmara/dexter/mara; dexter coat+hair no longer clipped; ref boards
- [CANON] Agent3: HD billboards for aruun, cigarra, bramvex (x4 ESRGAN re-cut); bramvex ref pack; refpack tool
- [CANON] Agent3: HD re-cut pipeline (x4 ESRGAN regions, refined alpha, optimized PNG); portraits from x4
- [CANON] Agent3: Aruun fidelity pass - re-rendered comparison board + engine shots, notes
- [CANON] Agent3: Aruun fidelity pass - sheet-projected albedo, hooked horns, beetle-mask head, ragged cape, asymmetric pauldrons, telescoping Morrow haft, skirt weights
- [CANON] Agent3: Aruun comparison board, denser mottling, spec + notes
- [CANON] Agent3: Aruun 3D model in engine — textures, rig, 15 animations, glb + CharacterModel scene, QA shots
- [CANON] Agent3: Aruun 3D reference pack (turnaround, detail boards, palette) + modeling tools scaffold
- [ART] Agent1: hub — Nerit's living lights cast coloured pools
- [ART] Agent1: creature outline-pass guards (no SCRIPT ERRORs with outlines off)
- [ART] Agent1: character rim layer auto-assign, dust motes, Dominion red camp lights, metal camp material
- [ART] Agent1: 3D scatter — rocks, spires, dead trees, lichen rocks, dense dry grass + pebble ground cover
- [ART] Agent1: props/creatures move to PBR-lit detail shader, ink outlines off (draw calls halved)
- [ART] Agent1: shot.sh timeout scales with slow llvmpipe runs; PBR terrain baseline
- [LEAD] Scorecard: Agent 3 retrained as Canon Art Fidelity; modeling to Agent 4
- [LEAD] Lead: agent scorecard + grading policy
- [LEAD] Aruun HQ: torch SDF sculpt kit, conformal chitin plates, beetle-mask head, preview boards
- [LEAD] Lead: palettize portraits/icons for smaller builds
- [LEAD] Lead: SFX to OGG Vorbis (5MB->0.65MB)
- [LEAD] Lead: PBR textures to WebP (21MB->4.8MB); package excludes regenerable model textures
- [LEAD] package: exclude model reference boards and ML weights
- [LEAD] v0.7.0 playtest: world realism, text audit, 3D Aruun preview toggle
- [LEAD] Cigarra reference pack (turnaround, palette, spec) from hi-res views
- [LEAD] Aruun hi-res pass: hunched posture, shorter mask head, colour/roughness grade, skirt clipping QA
- [LEAD] Aruun: project texture from hi-res x4 references (clean front, no Morrow paint)
- [LEAD] Hi-res (Real-ESRGAN x4) reference views for Aruun and Cigarra
- [LEAD] Lead: target Godot 4.7 officially (features 4.7, validate on 4.7.2; 4.3 floor dropped)
- [LEAD] Lead: text audit — American spelling to match the bible, 4 lore-accuracy fixes in dialogue, remove production citations from codex text

## Earlier
- v0.0.0 → v0.6.0: foundation, canon DB, story (39 dialogues), 37 SFX + 6 music tracks, Red Reaches world, 5 creatures, VFX, UI, hub, Habitat builder, boss, both endings, save/continue.
