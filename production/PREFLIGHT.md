# Pre-Flight List (Lead) — improvements to complete before adding more

Updated: 2026-10-11, before Sprint 1 (nothing of v2 is built yet; this is the foundation list).

| # | Improvement | Why | Effort | Impact |
|---|---|---|---|---|
| 1 | Creator approves GDD v2, the Seven, and the Art Bible (or marks changes) | Everything else builds on these | S | Critical |
| 2 | v2 project skeleton + CI (tests, smoke, release zip) | Safe, fast iteration and delivery | S | Critical |
| 3 | Combat core (fixed-tick sim, data-driven moves) with unit tests | The game is the fight | L | Critical |
| 4 | Two critters (Haldor, Sessa) fully playable first, then the other five | Test the triangle and balance early | M | High |
| 5 | Controls prototype on the creator's phone (2 touch schemes) | Feel is decided on-device | M | Critical |
| 6 | Character rigs + toon/outline look + procedural animation for the first two | Prove the art style in engine | M | High |
| 7 | Bot tournament harness and matchup matrix | Make "equally powerful" measurable | M | High |
| 8 | Perf telemetry port from v1 (report screen, hitch log) | Real-device numbers | S | High |
| 9 | Decide stakes rules, bonded-character rules, roster/team format (DECISIONS.md) | Avoid late redesign | S | High |

Legacy (v1) items parked in `archive/v0.15.0-before-restart`: dialogue lag fix (WorldFreeze), perf reporter, QA harness, Ledger. We port them only when v2 needs them.

## Update 2026-10-12 (v0.3.1)
Landed: three abilities + Last Stand input, faster movement with cancel windows, bigger arenas, Move Effect Gate (81/81 moves have a measured effect: v2/tools/out/move_audit.md), roles + rule modifiers in the sim, six-button layout, scaled ring.
Open before adding more:
1. **Balance:** overall win rates 42.8-55.3% (target 45-55); some matchups beyond 40/60 (noise at ~28 bouts per cell is about +-9%); role-pair soft-counter targets (<=54/46, expert >=46%) NOT yet verified. A full run takes ~8 min single-core; use sharding (shard=K/4) for 4x. Last nudge: nyxaris x1.07, aruun x0.97, scarlith x0.98, zephyr x0.98.
2. **Per-ability VFX** (art agent task, not done) and animation fluidity.
3. **Arena integration of statuses/zones** (HUD chips with real remaining time, real-radius zones) not done.
4. **Phone test** of v0.3.x controls (6 buttons, layout A/B).
5. Backdrop lookdev, audio, display font.

## Update v0.4.0 (Lead, 2026-10-12): juice pass
Landed: 64 procedural sound effects (one distinct sound per ability, v2/audio/sfx, generator tools/gen/gen_sfx.py) via BoutAudio; 36 ability/basic icons (v2/art/icons, gen_icons.py) on the buttons; per-ability cast VFX with a pop-up ability glyph (AbilityVfx + FxPrims), per-critter hit styles, REAL zones/projectiles/traps/ghosts/decoys rendered from sim.state() entities at their real radius and life, status auras from real status ticks (BoutVfx); VFX lab (v2/src/fx/vfx_lab.tscn) renders every ability; coverage test (every ability has icon + sound + VFX recipe).
Open before adding more:
1. **Perf:** bout draw calls avg 100 / max 140 (was 87/103), under the 150 flagship budget but above the 110 mid-range one; add an effects-quality setting (Low: cap live effects at ~40, no entity decor, fewer particles).
2. **Phone test** of feel/audio/VFX (volume mix, effect size, readability while moving fast).
3. **Hit-time and projectile VFX** only partly verified in renders (cast effects verified in the lab; hit styles and entity visuals verified by code, not every case by eye).
4. Balance matrix and role-pair targets still to finish; music still empty (slots reserved).
5. Realism ladder R2 for characters, backdrop lookdev, display font.
