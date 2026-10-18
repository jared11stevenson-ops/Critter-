# R&D digest log (newest first). Verdicts: ADOPT (plan a step), WATCH (re-check next time), IGNORE (say why).
Written by the weekly research routine and by Lead sessions. Plan: production/RND_STRATEGY.md.

## 2026-10-18 (lab result F6: evolutionary move design, Lead session)
- Tool: v2/tools/lab/evolve_moves.gd (in-memory only, power budget +5%, successive halving, holdout of 112 fresh bouts). Test: bramvex_diplomacy1 against the 7 other critters, standard AI. Reports: v2/tools/out/lab/evolve_bramvex_bramvex_diplomacy1_s{1,2,3}.md.
- Run 1 (28 bouts per candidate, no halving) FAILED: evolved 32% vs original 43% on holdout; selection was fitting noise. Fixed with successive halving and larger holdout.
- Runs 2-4 (three seeds): holdout win rate original 42-43% vs evolved 34.8% / 42.9% / 50.9%. Not significant (112 bouts, about +/-5 points each). Consistent direction across all three seeds: REACH up (2.91-2.98 from 2.80) and DAMAGE down (4.8-5.6 from 6.0), hitstun down. Reading: the search says Bramvex's strength is range, not damage per hit.
- Verdict: tool WORKS and is safe; result is INCONCLUSIVE, not a design change. Next test (queued in AUTONOMY.md): validate the seed-3 variant on 400+ fresh bouts, and add a second panel at expert AI before anyone proposes a data change. No game data was modified.

## 2026-10-18 (dev-process sweep, Lead session)
- Full comparison in production/DEV_LANDSCAPE.md. ADOPT: provenance ledger + CI check, golden-replay determinism test, animation lint, render-budget gate, Android CI export, pre-registered beta gates. WATCH: godot-mcp, learned motion matching (humanoid only), VLM QA as a filter (about 0.5 precision alone), rollback netcode. IGNORE: wishlist/Next Fest tactics until beta.
- Platform policy: Steam rewrote AI disclosure in Jan 2026 (shipped AI content disclosed, dev-only tools exempt). Apple/Google sources conflict: verify on official pages before any submission.
- My own correction: the v1 ASSET_LICENSES ledger was deleted in the cleanup; a v2 ledger now exists at design/v2/ASSET_LICENSES.md with TO VERIFY items.

## 2026-10-18 (seed, Lead session)
- Godot 4.6/4.7: IK modifier family, SpringBoneSimulator3D, RetargetModifier3D, Jolt default. ADOPT (used by skinned rigs; E5 will use IK).
- NVIDIA Kimodo (open text-to-motion, humanoid skeletons only, Mar-Apr 2026). WATCH: only for humanoid-ish critters as reference (E7); check licence and CPU speed.
- UniRig (open auto-rigging, SIGGRAPH 2025): WATCH, benchmark as E10 when disk allows (weights size unknown; skinning stage release status unclear).
- DeepMimic-style physics characters: IGNORE for runtime (GPU-heavy, brittle); ADOPT the idea as offline baked reactions (E6).
- Industry AI-in-games reports (2026): no verified shipped game with player-mirroring ghosts found; WATCH for competitors; our E1 niche looks open.
- Measured here: sim runs about 8,600 ticks/s/core; 4 CPU cores, no GPU, about 5 GB disk free.
