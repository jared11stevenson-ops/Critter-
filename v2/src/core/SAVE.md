# Save system (v2/src/core/save)

## Files (all under `user://v2_saves/`)
| File | Meaning |
|---|---|
| `slot_<id>.json` | The save: `{version, saved_at, roster{...}}`. |
| `slot_<id>.json.bak` | The previous good save (copied before every overwrite). |
| `slot_<id>.json.tmp` | Transient; exists only mid-write. |
| `deaths_ledger.jsonl` + `deaths_ledger.mirror.jsonl` | Append-only record of every death. Never rewritten or pruned. |

## Write path (atomic)
1. Merge the deaths ledger into the in-memory state (a stale state cannot write a resurrection).
2. Refuse if the file on disk is from a NEWER schema version (never downgrade a player's save).
3. Write `slot.tmp`, flush, re-read and parse it to verify.
4. Copy the existing slot to `.bak`.
5. Rename `.tmp` over the slot (fallback: delete + rename if the platform refuses to replace; the `.bak` is already valid).

## Load path
Main file, else `.bak`. Run `SaveMigrations.migrate` (chain of `vN -> vN+1` steps; unknown/missing/future versions are refused and
the file is left untouched), build the `RosterState`, then merge the ledger.

## Schema versions (`SaveMigrations.CURRENT`)
- v1: prototype layout (`critters`, `fallen`, `money`). Kept only to exercise the migration chain in tests.
- v2: `{version, saved_at, roster}` where `roster` = `RosterState.to_dict()`.
To change the schema: bump `CURRENT`, add a `_vN_to_vN+1` step, add a test with a fixture of the old layout in `test_save.gd`.

## The hard rule: a death can never be reverted
Death is permanent (GDD pillar 1). Save-scumming (copy the save, fight, restore the copy on death) is the one exploit that would
destroy the stakes, and cloud restores, "restore backup" flows and file deletion are all ways it can happen by accident, so the
protection is structural, not a UI promise:

1. **Commit at the moment of death.** `RosterState.kill()` emits `critter_died`; `SaveSystem` (bound with `bind()`/`new_game()`/`load_slot()`)
   appends to the ledger FIRST and then saves the slot immediately, with no debounce (`autosave()` debounce applies only to non-lethal events).
2. **Append-only ledger.** Each line is `{profile, rec (JSON text), sum}`. `rec` is the full fallen record (name, species, chapters, epitaph, relic,
   last move), so the Wall of the Fallen can be rebuilt from the ledger alone. `sum` is a SHA-256 prefix over the exact bytes; torn or tampered lines
   are skipped. It is written to two files and read as a union, so losing one copy does not lose a death. Game code has no API to remove entries.
3. **Merge on every load and every save.** Any critter in the ledger is removed from the Rack and added to the Wall if missing (relic and last move
   re-granted), whatever save file was loaded: an older save, the `.bak`, or a hand-restored copy. Saving a state that still has a ledger-dead critter alive strips it first.
4. `profile_id` (random, created by `new_game`) scopes ledger entries, so deleting everything and starting a NEW game starts a clean profile.
   Uids (`c0001`, ...) are never reused: `next_uid` is bumped past every ledger uid.

Known limit: a player who deletes the whole `user://v2_saves` folder (or reinstalls) loses the ledger too; that is a new game, not a revert. A cloud-synced
ledger (or the platform's cloud save) would be needed to cover reinstalls, and a determined user can always edit files; this protects against honest accidents and casual save-scumming.

## API
```gdscript
var sys := SaveSystem.new()                    # or the GameSave autoload: GameSave.system / GameSave.roster
var roster := sys.new_game("1")                # new profile, bound to slot "1"
sys.save("1", roster)                          # -> {ok, error}
sys.autosave("care")                           # debounced (5 s); true if written now
sys.flush()                                    # write anything deferred (called on pause / close by GameSave)
var r := sys.load_slot("1")                    # -> {ok, state, error, source, migrated_from, deaths_merged}
```
