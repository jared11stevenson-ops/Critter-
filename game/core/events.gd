extends Node
## Global event bus. Systems talk through these signals so art, gameplay and UI stay decoupled.
## Owner: Lead. Add signals here (never ad-hoc on other autoloads) and document the payload.

# --- Flow ---
signal scene_ready(scene_name: String)
signal objective_changed(text: String)
signal toast(text: String, kind: String)            # kind: "info", "codex", "item", "warning", "trust"

# --- Party / combat ---
signal party_member_changed(character_id: String)   # the player-controlled partner changed
signal actor_damaged(actor: Node, amount: float, source: Node)
signal actor_died(actor: Node)
signal ability_used(character_id: String, ability_id: String)
signal knack_cost_changed(character_id: String, value: float, max_value: float)  # strain / future-noise
signal enemy_captured(species_id: String)
signal boss_phase_changed(phase: int)

# --- Understanding ---
signal scan_started()
signal scan_finished()
signal codex_unlocked(entry_id: String)

# --- Narrative ---
signal dialogue_started(dialogue_id: String)
signal dialogue_finished(dialogue_id: String)
signal trigger_entered(trigger_event: String)
signal world_flag_changed(flag: String, value: Variant)
signal trust_changed(character_id: String, value: int)
signal item_changed(item_id: String, count: int)
