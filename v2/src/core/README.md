# v2/src/core (Platform Engineer)

Pure services under tests in `v2/tools/qa/tests/`. See `AUTOLOADS.md` (what the Lead registers), `SAVE.md` (persistence rules).

| Area | Files |
|---|---|
| Services | `events.gd`, `settings.gd`, `input_actions.gd`, `save_service.gd` |
| Perf | `perf.gd` (autoload), `perf_stats.gd` (pure stats), `perf_report_model.gd` (text/graph logic), `perf_report_view.gd` (screen) |
| Roster model | `roster/`: `RosterState` (entry point), `Rack`, `CritterInstance`, `StoryRules` + `data/story/chapter_rules.json`, `BoutOutcome`, `BoutResolver`, `CareModel`, `Economy` + `data/story/rewards.json`, `Epitaph`, `StakesTier` |
| Save | `save/`: `SaveSystem`, `DeathsLedger`, `SaveMigrations` |

## Using the roster from other systems
```gdscript
var roster := GameSave.roster                       # RosterState
var c := roster.seal("haldor", "Hal")               # capture succeeded; chapter 1 unlocks
var mods := roster.stat_modifiers(c.uid)            # {damage, speed, poise, stamina} multipliers (stress / hurt) for bout set-up
var o := BoutOutcome.from_sim_result(sim.result(), 0, c.uid, StakesTier.BLOOD, "kragg", final_vit_ratio, min_vit_ratio)
var report := roster.apply_bout(o)                  # {outcome, reward, chapters, scar, died, ...}; death commits itself
roster.care(c.uid, "feed")                          # feed|clean|play|train|rest, 3 care points per session
roster.end_session()                                # neglect drift; refills care points
GameSave.autosave()
```
Rules recap: Sparring = small bond only; Contest = counts, scars, never kills; Blood Bout = counts, can kill (a `killed` outcome in lower tiers is downgraded to a loss).
A yield forfeits the reward and adds stress. Stress above 30 and Hurt (vitality < 50%) weaken the critter via `CareModel.stat_modifiers`.
Chapter rules, rivals and bond thresholds are data (`v2/data/story/`). Per-critter overrides and personal trials are stubbed to defaults (TODO for story).
