# Data requests (Agent 3 to Lead / Agent 2)

Everything below is something the data now assumes. No engine code was changed. Validate: `python3 tools/validate_data.py`
(rules, bonds, reactions, rivals) and `python3 tools/validate_regions.py` (region recipes; please call it from `validate_data.py` / `validate.sh`).

## 1. Engine issue found (bond estrangement flip-flop)
`Ledger.advance_bond()` re-checks `estrange_if` every time. A reconcile (`reconcile_to`) therefore bounces straight back to `estranged`
if the estranging event still exists (a broken promise stays broken, a `forced_exposure` event never disappears).
**Data workaround used:** every `estrange_if` is `{"all":[<cause>, {"not": <amends>}]}`, and `reconcile_if` is the amends event
(`type: "amends"`, `target: <character>`). Zephyr's entry was changed the same way (second `promised` event cancels the estrangement).
Optional engine fix: store `estranged_at_tick` and only count causes after it.

## 2. New tags (the shared vocabulary grew; all are in `ledger_rules.values` and, if player-visible, `summaries`)
Producers today are the **region descent events** (`game/canon/regions/*.json`, choice `records`). Gameplay that wants these tags
can also call `Ledger.record(type, "player", target, tags, {}, weight)`.

| Tag | Meaning | Who cares |
|---|---|---|
| privacy_respected, darkness_kept | left something in the dark | Nerit, Cigarra |
| forced_exposure | lit or scanned what did not ask | Nerit (strong -) |
| delay_used, consequence_faced, consequence_dodged | Mollusk's Borrowed Seconds | Mollusk, Aruun |
| pattern_respected, accepted_boundary, silk_taken, pattern_destroyed, extraction_refused | silk culture | Nyxaris |
| threshold_kept, sealed_kept, pressed_origin, threshold_breached | Pharilux's rule | Pharilux |
| salvage_fair, claim_jump, not_for_sale, trafficked, trafficking_exposed | value without ownership | Scarlith, Mara, Bramvex |
| tide_read, tide_disturbed, emotion_translated, flood_averted | Solmara | Solmara |
| exit_planned, evacuation, rescue_civilians, shelter, glory_seeking, neglect | Bramvex and carriers | Bramvex, Aruun, Mollusk, Mara |
| route_laid, route_closed, delivered, speed_only, shortcut | Solthrin | Solthrin, Zephyr, Aruun |
| foresight_used, improvised, chose_unseen, certainty_trusted | Cigarra | Cigarra |
| courier_delivered, rules_bent_fun, coercion, consent_asked | promises and consent | Zephyr, Mara |
| leverage, sacrifice_for_many, protect_personnel, waste, cruelty | Dexter | Dexter |
| redundant_design | Burden Architecture | Aruun, Mollusk |
| amends | event type `amends`, target = character, resolves an estrangement | everyone |

**Tags with no producer yet** (data exists, gameplay/events must emit them): `foresight_used` (Priced Foresight, system 19: emit when
Future-Noise is spent), `improvised`, `chose_unseen` (emit if the player dodges a Premonition ghost's predicted outcome),
`certainty_trusted`, `sacrifice_for_many`, `waste`, `redundant_design` (Burden Architecture builds), `shelter`.

## 3. Runtime for region recipes (Agent 2)
Files: `game/canon/regions/{canopy_fold,lumen_depths,rainward,frostbloom,briarwild}.json`. Fields (all data):
- `layers[]`, `ground.surfaces[]`, `sky`, `props[]`, `flora`, `creatures[]` (with `uses.{battle,labor,ecology}` per bible 53), `music`, `encounters` (`enemies[{species,weight}]`, `rivals[]`, `hazards[]`), `world_states[]` (ids are the bible affix list: flood, fire, war, migration, overgrowth, disease, extraction, predator_imbalance, political_control; `event_weight_mods` raise event weights while the affix is active), `bondable_here[]`.
- `descent_events[]`: `{id, title, kind (migration|convoy|stranded|marker|hazard|social|discovery|bond_test), weight, once, min_depth, when (spec), text, choices[]}`.
  Choice: `{id, label, result, records[{type,target,tags,weight}], requires (spec, optional), promise (optional {id,to,template})}`.
  Pick: filter by `when`, drop `once` events already taken (`Ledger.exists({"type":"descent_event","target":id})` or a flag), weighted random on `weight` (+ affix mods).
  On choice: call `Ledger.record(...)` for each record (region = the current region), and `Ledger.make_promise(...)` if `promise` is present. Also record `{type:"descent_event", target:event id, tags:["descent"], weight:0, data:{choice:id}}`.
- `Old Road marker` events teach Knack adaptations (Master Plan 22): the `grants` for those are not yet defined; the choice only records `discovered` + tags.
- New creature ids (thread_hopper, bough_stalker, glass_eel, spire_sleeper, levee_mole, storm_heron, mudback_crab, frost_moth, icefall_stalker, thorn_mantis, nectar_wasp, ...) are **not** in `canon.json` species yet. They are region data only; add to `canon.json` when art exists.
- `dominion_drone` is reused as the Dominion presence in every region.

## 4. New promise templates (ledger_rules.promise_templates)
`carry_bloom_word` (Briarwild, letter and spirit read `courier_delivered` and `coercion`), `hold_the_dark` (Lumen, Nerit; resolves on return).
Region events create these via `promise` (ids `zephyr_carry_bloom_word`, `nerit_hold_the_dark`). The Bond Contract UI should show them like the existing Zephyr promise.

## 5. Solthrin
- `canon.json` now has a minimal `solthrin` entry (so bonds, values and reactions validate). He has **no portraits, billboard, dialogue or hub spot**; reactions use `expr: "default"`. Needs `hub_npc_solthrin.json` (the `talked` event fires from `hub_npc_*` automatically) and portraits (calm, watchful, focused).
- His bond tags are produced in Rainward (leaf-mat), Frostbloom (ice road) and Briarwild (bloom front).

## 6. Other
- `rivals.json`: 6 new authored rivals (wren_calder, marek_vasko, joss_harrow, agent_pemberton, poacher_dara, ayla_fenwick), per-archetype `lines` (flee / defeated / negotiate / expose / release / bond) and more greetings (`exposed`, `defeated`, `bonded`). `lines` is a new key; the AI/dialogue layer can read it. No new traits or tactic strings were added.
- Portraits: Bramvex and Nyxaris have only `default`; Solthrin has none. Reactions use those names.
- `bonds.json` entries carry an extra `stage_hints` object (one line per stage) for the Bond Contract UI.
