extends Node
## Autoload `InputActions`: registers every gameplay InputMap action with keyboard + gamepad bindings.
## Touch controls (UI team) call Input.action_press / action_release with these same names.
## Static API so tests and tools can call InputActions.register() without the autoload.

const MOVE_ACTIONS := ["move_left", "move_right", "move_up", "move_down"]
const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "strike", "guard", "grab", "dodge",
	"ability1", "ability2", "ability3", "last_stand", "yield", "pause", "lock"]
const DEADZONE := 0.25

## action -> {keys: [Key], buttons: [JoyButton], axes: [[JoyAxis, sign]]}
const BINDINGS := {
	"move_left": {"keys": [KEY_A, KEY_LEFT], "buttons": [JOY_BUTTON_DPAD_LEFT], "axes": [[JOY_AXIS_LEFT_X, -1.0]]},
	"move_right": {"keys": [KEY_D, KEY_RIGHT], "buttons": [JOY_BUTTON_DPAD_RIGHT], "axes": [[JOY_AXIS_LEFT_X, 1.0]]},
	"move_up": {"keys": [KEY_W, KEY_UP], "buttons": [JOY_BUTTON_DPAD_UP], "axes": [[JOY_AXIS_LEFT_Y, -1.0]]},
	"move_down": {"keys": [KEY_S, KEY_DOWN], "buttons": [JOY_BUTTON_DPAD_DOWN], "axes": [[JOY_AXIS_LEFT_Y, 1.0]]},
	"strike": {"keys": [KEY_J], "buttons": [JOY_BUTTON_X], "axes": []},
	"guard": {"keys": [KEY_K], "buttons": [JOY_BUTTON_LEFT_SHOULDER], "axes": []},
	"grab": {"keys": [KEY_L], "buttons": [JOY_BUTTON_Y], "axes": []},
	"dodge": {"keys": [KEY_SPACE], "buttons": [JOY_BUTTON_A], "axes": []},
	"ability1": {"keys": [KEY_U], "buttons": [JOY_BUTTON_B], "axes": []},
	"ability2": {"keys": [KEY_I], "buttons": [JOY_BUTTON_RIGHT_SHOULDER], "axes": []},
	"ability3": {"keys": [KEY_O], "buttons": [JOY_BUTTON_RIGHT_STICK], "axes": []},
	"last_stand": {"keys": [KEY_Q], "buttons": [JOY_BUTTON_LEFT_STICK], "axes": []},
	"yield": {"keys": [KEY_Y], "buttons": [JOY_BUTTON_BACK], "axes": []},
	"lock": {"keys": [KEY_TAB, KEY_E], "buttons": [JOY_BUTTON_PADDLE1], "axes": []},
	"pause": {"keys": [KEY_ESCAPE, KEY_P], "buttons": [JOY_BUTTON_START], "axes": []},
}


func _ready() -> void:
	register()


## Idempotent: (re)creates each action with its bindings, keeping any existing deadzone override out of the way.
static func register() -> void:
	for action: String in ACTIONS:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action, DEADZONE)
		var b: Dictionary = BINDINGS[action]
		for k: int in b["keys"]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k as Key
			InputMap.action_add_event(action, ev)
		for btn: int in b["buttons"]:
			var jb := InputEventJoypadButton.new()
			jb.button_index = btn as JoyButton
			InputMap.action_add_event(action, jb)
		for ax: Array in b["axes"]:
			var jm := InputEventJoypadMotion.new()
			jm.axis = ax[0] as JoyAxis
			jm.axis_value = ax[1]
			InputMap.action_add_event(action, jm)


## Movement vector from the move_* actions (y down = +1), for InputProvider / CombatInput.move.
static func move_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")
