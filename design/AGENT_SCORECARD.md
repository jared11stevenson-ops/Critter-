# Agent Scorecard (Lead-maintained)

Graded after every hand-back. Usage-limit stops and user stops are **not** held against an agent;
only the quality of what it delivered per run.

## Criteria (each 1–5)
| Criterion | Meaning |
|---|---|
| **Output** | Deliverables completed vs. assigned, per run |
| **Quality** | How it looks/plays when the Lead checks it (screenshots, playthrough, comparison boards) |
| **Reliability** | Zero errors, validate passes, honors contracts/ownership, commits often |
| **Honesty** | Reports match reality; deviations stated plainly |
| **Fit to creator priorities** | Works on what the creator asked for right now |

Grade = average. **A ≥ 4.5 · B ≥ 3.5 · C ≥ 2.5 · D < 2.5**

## Policy
- **A** — rewarded: gets the next priority tasks and expanded ownership.
- **B** — continues on current scope.
- **C** — probation: one run to deliver a shippable result on a clear gate, or culled.
- **D** or two C runs in a row — **culled**: stopped, its scope reassigned to the best performer.

## Current grades (after v0.7.0 + mocap round)

| Agent | Output | Quality | Reliability | Honesty | Fit | Grade | Decision |
|---|---|---|---|---|---|---|---|
| **Agent 2 — Gameplay/UI** | 5 | 4 | 5 | 5 | 4 | **A (4.6)** | Rewarded: takes the **performance/lag** task, with authority over world shaders for perf |
| **Agent 4 — Animation** | 5 | 4 | 4 | 4 | 5 | **A− (4.4)** | Rewarded: owns **all character animation + 3D model integration** as default, Cigarra anims |
| **Agent 1 — Art/World** | 5 | 4 | 4 | 5 | 3 | **B+ (4.2)** | Benched (no cull): its scope is mostly delivered; lag partly from its realism pass → perf handed to Agent 2 |
| **Agent 3 — Canon Art Fidelity (retrained)** | 3 | 2 | 4 | 5 | 4 | C+ as modeler | **Retrained** (creator's call): 3D modeling → Agent 4. New role plays to its strengths: Real-ESRGAN sharper billboards/portraits/icons, canon fidelity audit, reference packs. Graded fresh in the new role. |

### Evidence
- Agent 2: delivered the entire playable slice (combat, AI, boss, UI, hub, habitat, save), proved both endings end-to-end, fixed real bugs (80 m/s knockback), cut draw calls 238→~125.
- Agent 4: mocap pipeline (BVH, retarget, foot-lock IK, Morrow pendulum) + 19 Aruun clips from CMU mocap in one run; Lead in-engine check shows a real walk cycle and full mace arcs.
- Agent 1: all 10 art deliverables, occlusion fade, realism pass under budget; but the PBR/scatter pass raised primitives to 222k and the creator reports lag.
- Agent 3: honest reports and good reference packs, but three passes have not yet produced a model that beats the 2D cut-out.
