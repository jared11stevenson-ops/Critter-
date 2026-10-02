class_name TouchInput
extends RefCounted
## Shared state written by the touch HUD and read by the PartyController.

static var move := Vector2.ZERO        # floating joystick, length 0..1 (screen space: +x right, +y down)
static var active := false
static var hold_button := false        # Burden HOLD button

static func reset() -> void:
	move = Vector2.ZERO
	active = false
	hold_button = false
