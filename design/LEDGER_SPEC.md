# The Ledger — CRITTER's shared memory (Lead-owned)

One log of "who did what to whom, where, and why", plus the systems that read it. Everything that makes the world
*remember* (bonds, promises, reactions, rivals, debrief, eras) is built on it, so they all agree on the facts.

Code: `game/core/ledger.gd` (autoload `Ledger`), `game/core/rivals.gd` (autoload `Rivals`).
Data: `game/canon/{ledger_rules,bonds,reactions,rivals}.json`. Validate data: `python3 tools/validate_data.py`.
Tests: `tools/qa/test_systems.tscn` (run by `tools/validate.sh`). **52 tests pass.**

## 1. Events
`Ledger.record(type, actor="player", target="", tags=[], data={}, weight=1, region="")`
- `type`: harmed, helped, chose, killed, contained, discovered, talked, promised, promise_resolved, bond_stage,
  descent, return, party_wipe, downed, rival_encounter, rival_resolved, reaction, …(free-form; filters match any string)
- `tags` are the **shared vocabulary**. Characters judge events through tags (`values`), the debrief renders tags
  (`summaries`), promises/bonds/reactions condition on tags. Current tags: harm_wildlife, calmed_wildlife, spared, nonviolent,
  protect_weak, burden, stewardship, braced_structure, extraction, dominion_favor, kill_wildlife, kill_dominion, combat, boss,
  casualty, discovery, curiosity, evidence, trust, containment, promise_*, rival_*, social, return, descent. **Add new tags freely, but
  add them to `values` for the characters who care and (if player-visible) to `summaries`.**
- `weight` 0..5 (0 = bookkeeping, 1 routine, 2 notable, 3 significant, 4 major, 5 era-defining).
- Automatic recording (no gameplay code needed): enemy deaths, partner downs, ability use (tallies), contained specimens,
  codex unlocks, finished `hub_npc_*` dialogues, and **flags** listed in `ledger_rules.flag_events` (e.g. `grazers_harmed`,
  `ochre_span=braced`). To make a new flag matter, add it there.
- Gameplay MUST call: `Ledger.begin_run("red_reaches")` on descent, `Ledger.end_run(all_conscious)` on exfil/return,
  `Ledger.record("party_wipe","player","",["casualty"])` on a wipe.

Queries: `events_where(f)`, `count(f)`, `exists(f)`, `last(f)`, `memory_of(entity)`. Filter keys: type, actor, target, entity,
region, tag, tags_any, tags_all, since, min_weight, data_eq, count_min.

## 2. Opinion
`Ledger.opinion(character_id)` = Σ weight × the character's value for each tag on the player's events (optionally limited to
`data.witnesses`). `opinion_label()` → devoted/trusting/warm/neutral/wary/hostile. `opinion_shift_lines()` → debrief lines.
Values live in `ledger_rules.values` (every playable/bondable character needs a table; keep values faithful to the bible:
Aruun = burden/structures, Zephyr = promises, Bramvex = exits/casualties, Mara = stewardship, Dexter = leverage…).

## 3. Promises (Zephyr's Promise Law as a mechanic)
`Ledger.make_promise(id, to, template_id)`. Template (`ledger_rules.promise_templates`): `wording`, `letter[]` and `spirit[]`
(lists of filters that must all match since the promise was made; `{"none": filter}` = must not match), `break_on[]`,
`resolve_on` ("return" = judge at the next return, "" = judge as soon as satisfied).
Outcome: **kept** (letter+spirit) · **loophole** (letter only) · **bent** (spirit only) · **broken** (neither).
Each outcome is an event tagged `promise_<status>` so characters react by their values (Zephyr rewards loopholes, Aruun distrusts them).

## 4. Bond Contracts — how sapient characters are acquired
`bonds.json`: per character `stages` (unmet → … → bonded), `requires[stage]` (a spec), `estrange_if`, `reconcile_if`.
Build each bond test around the character's *contradiction* (bible). Stages advance automatically as the ledger changes
(`Ledger.bond_stage(id)`, signal `bond_changed`). A failed test sends the character to **estranged**, never silently lost.
Spec DSL: `all[] any[] not event{filter} none{filter} opinion_min{character,min} promise{id,status_in[]} flag tally_min{key,min}
stage{character,at_least} rival{id,state_in[]}`.

## 5. Reaction Matrix
`reactions.json`: per character `{id, trigger, when(spec), once, priority, expr, text}`. Triggers: return, hub_idle, camp, descent,
boss, rival_met, bond_up, era_start, pause_menu. `Ledger.take_reaction(character, trigger)` returns the best unseen entry (or `{}`).

## 6. Debrief
`Ledger.debrief_lines()` → "what changed because of you" for this run; `Ledger.opinion_shift_lines()`.

## 7. Ledger Rivals (our own nemesis-style system)
`Rivals`: a **small authored-archetype cast** (survey chief, poacher, Free Scale cell leader, Helix recovery agent) — each with
traits, a **memory of how you fight** (per-encounter ability tallies), **adaptations** (counter-tactics, max 3), **scars**, grudge/respect,
and **greetings that remember**. API: `spawn`, `get_rival`, `active_in(region)`, `encounter_begin(id)`, `encounter_end(id, outcome, hit_by[])`,
`behavior_profile(id)` (tactics/aggression/flee_at/taunts for the AI), `greeting(id)`, `resolution_options(id)`.
Outcomes: defeated · escaped · negotiated · exposed · released · bonded (bondable archetypes only, after being released once).
**Design rules (kept deliberately different from other studios' patented systems; not legal advice — IP attorney review before launch):**
no army/fort hierarchy; no ranks or promotions gained by beating the player; no rival-vs-rival vendettas; rivals pursue faction objectives
driven by the Ledger, not personal revenge loops; non-lethal resolutions are first-class.

## 8. Contract for Agent 2 (gameplay) — integrate, don't fork
1. Call `begin_run/end_run/party_wipe` as above; show `debrief_lines()` + `opinion_shift_lines()` on the hub debrief and end card.
2. Rival encounter at the Drill Site (`foreman_orrin`) and Valley/Waystation (`poacher_vesk`): spawn from `Rivals.active_in("red_reaches")`,
   greeting via `Rivals.greeting`, AI uses `behavior_profile` (map tactics → behaviours; see list in rivals.json counters/adapt_lines),
   call `encounter_begin/encounter_end(outcome, hit_by)`, offer `resolution_options` as buttons when the rival drops below `flee_at`.
3. Bond Contract UI: show a character's `bond_stage`, the `test_hint`, and the live promise state; Zephyr is the first test case in the hub.
4. Use `Ledger.take_reaction(char, "return")` after returning to the hub (Reaction Matrix barks via the dialogue box).
