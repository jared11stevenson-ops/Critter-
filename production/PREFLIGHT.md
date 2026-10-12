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

## Update v0.5.0 (Lead, 2026-10-12): the career loop (first real game around the duel)
Landed (law-compliant, see design/v2/CREATOR_GDD.md): PLAY now starts a CAREER: Aruun is the tutorial critter (founder of the giraffe-beetle jar) with timed control tips in a safe training bout, then the SHELF (60 jars, Vitality rings, founder crown, champion/retired marks, per-critter record, LIFE STORY with 7 chapters each: unlocked ones readable, locked ones shown as redactions with their unlock condition; 49 chapters written from the lore), EXPEDITION (pick a homeland region + the critter you RISK -> wild bout to the death -> win = choose SEAL or FINISH -> SEAL requires an EXTRACTION bout; success captures a new critter, first of its species becomes the founder; failure loses the captive), TOURNAMENT (5-rung ladder, every fight lethal, Champion Tournament, then RETIRE or DEFEND), HEAL (30 scrap), WALL OF THE FALLEN (epitaph, chapters read, redacted chapters never read). Permadeath is committed immediately (deaths ledger). Vitality carries over between bouts; time passes (+10% heal for the others each bout). Rack capacity 60. Roster model: founder/retired/champion/ladder fields, species_seen. New test test_career.gd (27 test files green).
Open before adding more:
1. **Not yet built:** Habitat Jar diorama / autonomous civilization, breeding/retired families (deferred by creator), expedition exploration beyond one encounter, per-region ecology.
2. **Expedition rules v0:** one wild encounter + one extraction bout (the creator's loop wants exploration/observation/persuasion options); closing the app mid-expedition currently has no penalty (needs a committed-expedition record to stop save-scumming).
3. **Balance:** matrix not final; role-pair targets unverified; wild/tournament opponent difficulty is a first guess (profiles novice..expert).
4. **UI polish:** shelf screen verified at 1280x720 only (check 20:9 and tall phones), result panels use the shared theme, no audio on menus.
5. **Chapter prose** is a lore-faithful placeholder for the creator to rewrite.

## v0.7.0 — Habitat Jars (slice 1)
Done: per-species `Habitat` (data/career/habitats.json, 5-step ladder per species), saved in RosterState; jars advance in real time (1 habitat day per 10 min, max 48 days catch-up on load); only retired critters breed; descendants are peaceful family, not fighters; critters build the next structure on their own once the player supplies materials; player allocates scrap (feed / supply / expand) and collects settlement tribute; Jar panel shows stage, family, food, built structures, latest log line. Test: test_habitat.gd.
Open: structure names are placeholders (not lore); no visuals of structures inside the jar yet; cross-jar links (shelf network); observation (watch family lives); founder succession; breeding between species stays deferred; tune food/tribute numbers after playtest.

## v0.7.1 — Pharilux (8th playable)
Added from the approved concept sheet + lore bible entry 28: data/critters/pharilux.json, data/moves/pharilux.json (11 moves, all pass the Move Effect Gate), rig design (procedural placeholder until the Blender model), palette, VFX recipes (4 abilities + hit style), SFX (4), icons (4), region The Drowned Expanse, 7 lore chapters, jar ladder, rival = Cigarra (her blind spot). New mechanic: guard `parry_confuse` (Depth Veil). Role: Warden (second). Tap the selected jar again to open the jar view.
Open: Pharilux balance (first sharded run in tools/out/matrix.md), Homeland is "Unknown" in the lore bible but the sheet says The Drowned Expanse (kept the sheet).

## v0.8.0 — Expedition depth slice 1
Scout panel now has three approaches: STALK (5 scrap of bait; prey starts at 70% Vitality for Reader/Warden/Drifter/Binder, 85% for others; haul x0.8), DIRECT, PROVOKE (AI one skill level up; haul x1.7). Expedition wins now pay scrap + habitat materials for the sender's jar (feeds the Habitat Jars loop). Tests in test_career.gd. Jar view draws built structures and family. Balance round: all 8 critters 46.7-51.7% overall (30 bouts per pair, extremes remain).
Open: persuade/observe outcomes that change capture odds, region exploration, tournament rule modifiers, Pharilux model polish.

## v0.9.0 — Counterplay + skill stars
Two fight kinds only (Blood Bout, Practice); no role multipliers. Parry now cleanses statuses/DoT/compulsion; Tenacity halves repeated slow/root/confuse within 4 s; 1-3 skill stars per critter (display only). Matrix (30 bouts/pair): overall 46.7-54.3%. Open: Pharilux 25% vs expert AI and Bramvex 71% novice vs 36% expert (AI behaviour, not stats); counterplay gap audit per COUNTERPLAY.md; Pharilux model polish.

## v0.9.1 — Space to move
AI resets to neutral after exchanges (breath), retreat speed = advance speed, block push 0.8, tools/sim/spacing.gd measures spacing (mean gap 3.6 -> 4.1, far share 10% -> 22%, bouts ~+11 s). Matrix: 43.1-55.2% overall. Open: Pharilux bouts are long (83 s, 10% timeouts), ring-outs up to 25% for Aruun; needs playtest feel; player-side movement (dodge/dash options) not changed yet.
