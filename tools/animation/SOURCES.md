# Animation sources (Agent 4)

All character motion is built by `tools/animation` from **CMU Graphics Lab Motion Capture Database** clips,
retargeted onto our rigs and then hand-layered (style poses, foot-lock IK, Morrow pendulum, keyed arm/IK passes).

**License:** CMU mocap data is free for any use, including commercial products, modification and redistribution
(mocap.cs.cmu.edu "Use this data!" terms). Requested acknowledgement (also in `CREDITS.md`):
*"The data used in this project was obtained from mocap.cs.cmu.edu. The database was created with funding from
NSF EIA-0196217."* BVH conversion by Bruce Hahne (cgspeed), mirrored at github.com/una-dinosauria/cmu-mocap.

Trimmed copies live in `mocap/cmu/` (T-pose frame + used window +-0.5 s at 60 fps; `mocap/manifest.json` records
the original time offsets). Rebuild them with `python3 tools/animation/trim_mocap.py aruun [cigarra ...]`.

## Clip -> source (Aruun, `characters/aruun.py`)

| CMU trial | Game clips | Trimmed window (orig. timeline) | Source |
|---|---|---|---|
| `09_01` | run (heavy run loop) | 0.00-1.63 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/009/09_01.bvh |
| `124_07` | attack_1 | 1.80-3.99 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/124/124_07.bvh |
| `135_09` | reaching_strike | 1.70-3.68 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/135/135_09.bvh |
| `137_41` | idle; gravity_pull body base; hit, hit_back, hit_left, hit_right, hit_heavy body base | 3.80-10.73 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/137/137_41.bvh |
| `139_16` | downed, revive | 1.30-4.20 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/139/139_16.bvh |
| `139_25` | talk_idle | 1.53-5.53 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/139/139_25.bvh |
| `35_01` | walk | 1.27-3.40 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/035/35_01.bvh |
| `35_17` | jog | 0.10-1.87 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/035/35_17.bvh |
| `49_04` | dash | 0.55-2.08 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/049/49_04.bvh |
| `79_01` | attack_2, attack_3 | 0.05-3.85 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/079/79_01.bvh |
| `80_49` | beetle_rage | 3.50-6.10 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/080/80_49.bvh |
| `81_11` | burden_hold | 6.70-10.50 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/081/81_11.bvh |

Purely keyed on top of a mocap body: `gravity_pull` (left-hand reach/haul), hit reactions (directional recoil
keys over the idle body). `jog` is kept as an intermediate locomotion blend point.

## Cigarra (`characters/cigarra.py`, stand-in rig until her model exists)

| CMU trial | Game clips | Trimmed window (orig. timeline) | Source |
|---|---|---|---|
| `111_06` | revive (get up), downed (reversed) | 5.70-11.10 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/111/111_06.bvh |
| `137_41` | idle (7.2-10.2 s), attack_1 (crown flick), premonition, brain_skip, overwhelmed, hit x5 body base | 3.80-10.73 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/137/137_41.bvh |
| `138_11` | false_memory (arm-spread gesture), talk_idle | 0.00-4.17 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/138/138_11.bvh |
| `13_11` | dash (hop) | 1.05-3.46 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/013/13_11.bvh |
| `16_01` | leap (Grasshopper Thought: crouch-launch, tuck, land) | 0.00-2.43 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/016/16_01.bvh |
| `16_17` | walk | 0.03-2.17 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/016/16_17.bvh |
| `16_35` | run | 0.00-1.70 s | https://raw.githubusercontent.com/una-dinosauria/cmu-mocap/master/data/016/16_35.bvh |

Keyed on top of a mocap body: attack_1 (head/crown flick + right-hand IK), premonition (fingertips-to-temples IK,
wing flare), brain_skip (two-finger point IK, head glitch), overwhelmed (hands-on-head IK, rocking), hit reactions,
plus wing-cloak flare/flutter/lag layers on every clip.
