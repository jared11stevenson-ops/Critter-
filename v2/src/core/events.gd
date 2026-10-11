extends Node
## Autoload `Events`: typed signal bus. Systems emit here; UI/audio/analytics listen. No state lives here.
## Stakes ints follow StakesTier (0 Sparring, 1 Contest, 2 Blood Bout).

# --- bout flow ---
signal bout_started(critter_a: String, critter_b: String, stakes: int)
signal bout_ended(result: Dictionary)             # {winner, reason, killed, ...} as returned by CombatSim.result()
signal yield_offered(critter_uid: String)         # low-vitality Yield / Last Stand decision
# --- roster / story ---
signal critter_sealed(critter_uid: String, species: String)
signal critter_died(critter_uid: String, cause: String)
signal chapter_unlocked(critter_uid: String, chapter: int)
signal bond_changed(critter_uid: String, bond_level: int)
signal injury_gained(critter_uid: String, scar_id: String)
# --- economy ---
signal currency_changed(kind: String, new_total: int)
# --- platform ---
signal settings_changed(key: String, value: Variant)
signal save_completed(slot: String)
signal save_failed(slot: String, reason: String)
signal pause_requested(paused: bool)
signal toast_requested(text: String)
