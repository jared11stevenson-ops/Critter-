class_name InputProvider extends RefCounted
## Source of one fighter's CombatInput. BoutScene calls frame_update(dt) every render frame and tick() once per 60 Hz sim tick.
## Presses that arrive between two ticks are latched, so a fast tap on a 144 Hz phone is never lost (the sim adds its own 6-frame buffer).

func frame_update(_delta: float) -> void:
	pass

func tick(_sim: CombatSim, _idx: int) -> CombatInput:
	return CombatInput.new()

## Called by the scene each frame with the camera's right/forward vectors on the sim plane (player providers map the stick with them).
func set_view(_right: Vector2, _forward: Vector2) -> void:
	pass

## Drop any latched presses (used when the bout ends).
func clear() -> void:
	pass
