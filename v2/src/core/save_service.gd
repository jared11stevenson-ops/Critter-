extends Node
## Autoload `GameSave`: owns the live SaveSystem + RosterState for the running game and autosaves on lifecycle events.
## Gameplay code: GameSave.roster.apply_bout(...) then GameSave.autosave(). Deaths commit instantly on their own.

signal roster_loaded(state: RosterState)

var system := SaveSystem.new()
var roster: RosterState
var slot := "1"


func start_new(p_slot: String = "1") -> RosterState:
	slot = p_slot
	roster = system.new_game(slot)
	system.save(slot, roster)
	roster_loaded.emit(roster)
	return roster


func continue_game(p_slot: String = "1") -> bool:
	var r := system.load_slot(p_slot)
	if not r["ok"]:
		return false
	slot = p_slot
	roster = r["state"]
	roster_loaded.emit(roster)
	return true


func autosave(reason: String = "") -> bool:
	return system.autosave(reason)


func _notification(what: int) -> void:
	# app backgrounded / closing: write anything deferred
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		system.flush()
