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

## 7. Region lore layer, Red Reaches recipe and gear (Agent 3, content)
No engine code was changed. New data: `game/canon/regions/red_reaches.json` (full recipe, previously missing), `game/canon/gear.json`, and a lore layer
on all six region files. Validate with `python3 tools/validate_regions.py`, `python3 tools/validate_gear.py`, `python3 tools/spellcheck_canon.py`
(all three are called from `tools/validate.sh`; the spell pass needs `pip install pyspellchecker` and is skipped if absent; names live in `tools/lore_words.txt`).

### 7.1 New region keys (all data)
- `story {title, logline, acts[3]}`: each act has `trigger` (Ledger spec DSL), `completes_flag` (a bool flag; each one has a `ledger_rules.flag_events` entry, so setting it records a Ledger event), `unlocks[]` (side quest / secret ids), `reward_gear[]`, and for act 3 `variants[{id, when, text, sets_flag}]` (pick the first whose `when` matches; set its flag; show its text).
- `side_quests[]`: `{id, title, giver, landmark, summary, choices[{id,label,result,records[],consequence,sets_flag}], cares[], reward_gear[]}`. Choices work like descent-event choices (`records` go to `Ledger.record`, region = current region). `sets_flag` is a bool `GameState.set_flag` call. `consequence` is the epilogue line to show later (hub, codex or journal). A quest is offered once the act that lists it in `unlocks` has completed; it is done when any choice is taken.
- `secrets[]`: `{id, name, hint, how_found, reward, ledger_tags, reward_gear[]}`. Triggers are described in prose in `how_found`; Agent 2 needs a per-secret trigger (location + condition) when the level layout exists.
- `landmarks[]`, `ambient {npcs[], creature_behaviors[]}` (NPC `reacts {flag, line}`: after that flag is set, the NPC may say the line), `loot_table[]` (`{item, weight, source, rarity}`; `item` is a `gear.json` material id), `mood {palette, weather[], sounds[], music_slots[]}`.
- Act-completion flags: `rr_act1_done`.. `rr_act3_done`, `cf_`, `ld_`, `rw_`, `bw_`, `fb_` equivalents. Quest flags such as `rr_wells_kept` are plain bool flags; no `flag_events` entry is needed because the choice already records.
- Red Reaches `world_states` `event_weight_mods` name events `rr_pylon_night` and `rr_grazer_run`, which exist in its `descent_events`.

### 7.2 gear.json runtime
- Slots: weapon, charm, garment; one of each slot equipped per character (suggest an equipment screen in the Bond/Party UI, plus a Handler inventory).
- `stats[]` is `{stat, op: add|mult, value}`. `stat` is a `balance.json` path. Aruun and Cigarra paths resolve in `balance.json` today. All others use `<character>.<hp|speed|accel|friction|dash_dist|dash_time|dash_iframes|dash_cd|poise>`; **please add a `balance.json` section per remaining character** (nerit, mollusk, zephyr, nyxaris, pharilux, scarlith, solmara, bramvex, solthrin) with at least those keys, or read `Balance.v()` with a default so gear never errors. `global.*`, `pickups.magnet_radius` and `burden.*` apply to the whole party while the item is equipped.
- Apply order: base, then all `add`, then all `mult`. Direction rules for "buff vs cost" are in `tools/validate_gear.py` (`LOWER_IS_BETTER`).
- Equipment should be applied in `Actor` setup (`Balance.v("aruun.hp") + gear adds` ... ); the loadout can be stored in `GameState` as `{character: {weapon, charm, garment}}` and saved.
- Items are granted by the `reward_gear` of the act, quest or secret that names them (grant on completion of any choice of a quest). Aruun's items are also the visible cosmetic set for his 3D model (cape, pauldrons, mace head); no art is made yet.

### 7.3 Hook ids (`hooks[]`, special effects not expressible as stats; engine or kits must implement or ignore)
| Hook | Item | Effect wanted |
|---|---|---|
| `morrow_brace_on_reaching_strike` | aruun_morrow_foundation | Reaching Strike leaves a 3 s brace field at the impact point that halves damage to allies standing in it |
| `dead_route_replay` | cigarra_dead_route_sphere | Premonition also shows the last 2 s of each ghost's path in reverse |
| `light_relocation_range` | nerit_stilled_lantern | Light Relocation range +30 percent; relocated light never wakes sleeping enemies |
| `borrowed_seconds_extends_with_anchor` | mollusk_unfinished_anchor | Temporal Inertia duration +25 percent; ends with a visible "consequence" pulse |
| `pollination_trail_on_dash` | zephyr_everbloom_sprig | Dash leaves a petal trail that slows enemies for 1.5 s |
| `silk_pattern_zone_on_dash` | nyxaris_unworn_garment | Dash lays a short cold-silk strip that slows and marks enemies |
| `sealed_oath_aura` | pharilux_amber_oath_mantle | Allies within 4 m take 10 percent less damage while a promise is active |
| `ledger_blank_page_unsellable` | scarlith_not_for_sale_ledger | Item cannot be sold or traded (`not_for_sale` Ledger tag on first equip) |
| `tide_read_preview` | solmara_brass_gauge | Shows the next hazard timing (flood, pulse, tremor) on the HUD 2 s early |
| `diplomacy_stagger_instead_of_damage` | bramvex_vigil_diplomacy | Heavy hit staggers longer and records `nonviolent` on non-lethal clears |
| `laid_path_can_be_closed_by_player` | solthrin_unlit_road_mantle | A path he lays can be closed by interacting with it (records `route_closed`) |

### 7.4 Other asks
- Materials (`gear.json materials`, 48 entries across six origin regions, plus the five existing `balance.json` pickups): add a crafting/inventory UI later; `consumable` kind items restore HP or a resource (`keth_water_flask`, `plankton_light_vial`, `taro_root`, `steam_lily_petal`, `honey_thistle_comb`). Loot tables use `weight`, `rarity` and `source` (drop source text), and should be rolled per region at chest, creature-drop and secret rewards.
- New creature ids used by the lore layer exist as ambient behaviors only; `canon.json` species still lack them (see section 3).
- Moods: `mood.palette` (primary, secondary, accent, shadow, highlight and region-specific keys) should drive the region's grading and fog; `mood.music_slots[].slot` names are the cue slot ids for the audio pass (`tools/audio`).
- Ambient NPC `schedule` is descriptive text for now.

## 8. Red Reaches living NPCs (Agent 3 content for Agent 2 runtime)
Data: `game/canon/npcs/red_reaches.json` (12 NPCs), `game/canon/npcs/red_reaches_ambient.json` (24 environmental lines), 60 dialogue files `game/narrative/dialogue/rrn_<npc id>_{meet,repeat,quest,turnin,react}.json`, 10 new `codex.json` entries (`place_red_span_remnant`, `place_spanwright_yard`, `place_well_line`, `place_grazer_flats`, `place_augur_pit`, `place_waystation`, `place_boulder_pass`, `lore_load_marks`, `lore_keth_tally`, `lore_permit_7k`). Validate: `python3 tools/validate_npcs.py` (in `tools/validate.sh`; the spell pass also covers these files).
Cast: oda_keth, tavik_roon, hobb_sarrane, imre_dahl, ilsa_brandt, pel_narr, vesk_dunmore, nuru_tamsin, odalys_penhallow, bede_alcott, idris_voll, dessa_harl. All sapient people, none owned.

### 8.1 Runtime needs
1. **Stations.** red_reaches.json has no "camp" ids, so `schedule[].station` uses hub ids that already exist there (layer ids, spoke ids, spoke `hub` ids, landmark ids; e.g. `waystation`, `drovers_rest`, `salt_pans`, `span_approach`, `drill_basin`, `well_line`, `grazer_flats`). Map each to a world position (a `site` id gives an exact spot, else use the spoke trigger pos). `when` is dawn | day | dusk | night.
2. **Derived flags `ledger_<tag>`.** Dialogue and bark gates only read flags. Please extend `DialogueRunner.sync_derived_flags()` (and the bark gate) so `ledger_<tag>` is true when `Ledger.exists({"tag": <tag>})` for the current save. Tags used: braced_structure, claim_jump, salvage_fair, extraction, consent_asked, dominion_favor, trafficked, trafficking_exposed, threshold_breached, threshold_kept, darkness_kept, forced_exposure, protect_weak. The validator rejects `ledger_` flags whose tag is unknown.
3. **Dialogue events.** `rec:<id>` -> `Ledger.record(...)` using that NPC's `records[<id>]` (`type, target, tags, weight`; region = red_reaches; actor = player). `offer:<quest id>` -> mark the side quest as offered (the giver NPC only). `lead:<id>` -> optional journal hint for an event, site, act or quest. All events arrive through `DialogueRunner.event_emitted`.
4. **Speaker names and portraits.** `who` is the NPC id. `Canon.display_name(id)` should fall back to `npcs/red_reaches.json` `name`; `UiKit.char_color` / `portrait` need the NPC `look.palette[0]` for the badge until portraits exist. Portraits needed per NPC: the expressions in `portrait_expressions` (all have `default`). Until art exists the initial badge is fine.
5. **Flags set by NPC dialogue.** `rrn_<npc id>_met` is set in each `meet`; `rrn_<quest>_offered` etc. mark offers. Play `meet` once (gate on `rrn_<id>_met`), then `repeat`; play `quest` when `unlocks` allows (act flag) and the offer flag is not set; play `turnin` after the quest's `sets_flag` is true; play `react` when an act flag or ending flag has just changed.
6. **Barks.** `barks[]` use `if`/`if_not` flags like hub_ambient.json; ambient lines (`kind` sign | placard | wind | overheard) use the same gates. `wind` lines are subtitle-style, `sign` and `placard` are interactable props at the station.
7. **Known canon note.** The `ambient.npcs` entry for Oda in red_reaches.json lists her as a `plate beetle`; Plate Beetle is non-sapient WILDLIFE canon, so the NPC file describes her as a Keth (sapient, slate-shelled, kin to but not the same as the wildlife). Please treat the NPC file as authoritative for species.
8. **Rival overlap.** Vesk Dunmore is the authored rival `poacher_vesk`; the NPC is his claims-broker, truce-flag form (no weapons). When the rival fight is active, hide this NPC.
