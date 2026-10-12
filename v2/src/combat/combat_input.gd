class_name CombatInput extends RefCounted
## One per fighter per tick (INTERFACES.md). The sim edge-detects the button fields
## itself, so a held button never repeats an action.
##  move         world-plane stick (x, y = world z), length <= 1
##  strike_tap   light strike (pulse)         strike_hold  heavy strike (raise when the hold threshold elapses)
##  guard        LEVEL, hold to guard          grab / dodge / ability1 / ability2  presses
##  ability1/2/3 are the three main abilities; last_stand is its own flag (works only while state.can_last_stand)
##  grab: universal Grab = Guard + Strike pressed together (UI sets `grab`; the sim also treats guard held + strike_tap as a grab)
##  yield_pressed ends the bout (loser lives)
var move := Vector2.ZERO
var strike_tap := false
var strike_hold := false
var guard := false
var grab := false
var dodge := false
var ability1 := false
var ability2 := false
var ability3 := false
var last_stand := false
var yield_pressed := false

func clear() -> void:
	move = Vector2.ZERO
	strike_tap = false
	strike_hold = false
	guard = false
	grab = false
	dodge = false
	ability1 = false
	ability2 = false
	ability3 = false
	last_stand = false
	yield_pressed = false
