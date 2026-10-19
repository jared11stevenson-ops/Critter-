extends RefCounted
## Key poses and timing curves for skinned critters (see skinned_rig.gd for the axis conventions). Currently authored for Bramvex
## (hunched sergeant: economical, committed, weight shifts; the free left hand is the Command Hand; wings are the counterweight and the shield).
## A pose is {bone: Vector3(roll, pitch, yaw) degrees, "root": Vector3 metres (+x forward, +y up)}; partial poses are merged over IDLE.
## Hanging arm: roll +/-72..86 lowers it (right +, left -), pitch negative = forward. Elbow = arm_lo yaw (right +, left - bends it forward).
## Leg: thigh pitch negative = forward, shin pitch positive = knee bend. Spine/neck pitch positive = lean forward. Yaw positive turns left.

const WALK_RATE := 8.0

const IDLE := {
	"root": Vector3(0, -0.04, 0),
	"hips": Vector3(0, 4, 0), "spine": Vector3(0, 9, 0), "chest": Vector3(0, 7, 0), "neck": Vector3(0, -6, 0), "head": Vector3(0, -9, 0),
	"arm_up_L": Vector3(-74, -6, 0), "arm_lo_L": Vector3(0, 0, -16),
	"arm_up_R": Vector3(68, -24, 0), "arm_lo_R": Vector3(0, 0, 38),
	"th_L": Vector3(0, -3, 0), "sh_L": Vector3(0, 10, 0), "th_R": Vector3(0, 4, 0), "sh_R": Vector3(0, 12, 0),
}

## Attack styles: [anticipation, impact, recovery] partial poses merged over IDLE.
const STYLES := {
	"strike_light": [   # a short committed thrust of the club; the left hand points down the line of the thrust
		{"root": Vector3(-0.16, -0.08, 0), "spine": Vector3(0, -2, -14), "chest": Vector3(0, -4, -10), "hips": Vector3(0, 2, -12),
			"arm_up_R": Vector3(66, 44, 0), "arm_lo_R": Vector3(0, 0, 104), "arm_up_L": Vector3(-62, -30, 0), "arm_lo_L": Vector3(0, 0, -34),
			"th_L": Vector3(0, -16, 0), "sh_L": Vector3(0, 12, 0), "th_R": Vector3(0, 22, 0), "sh_R": Vector3(0, 30, 0), "head": Vector3(0, -10, 6)},
		{"root": Vector3(0.58, -0.10, 0), "spine": Vector3(0, 18, 16), "chest": Vector3(0, 14, 10), "hips": Vector3(0, 6, 14),
			"arm_up_R": Vector3(82, -74, 0), "arm_lo_R": Vector3(0, 34, 0), "arm_up_L": Vector3(-82, -56, 0), "arm_lo_L": Vector3(0, 0, -4),
			"th_L": Vector3(0, -42, 0), "sh_L": Vector3(0, 10, 0), "th_R": Vector3(0, 30, 0), "sh_R": Vector3(0, 6, 0), "head": Vector3(0, -16, -4)},
		{"root": Vector3(0.30, -0.06, 0), "spine": Vector3(0, 14, 4), "chest": Vector3(0, 10, 2),
			"arm_up_R": Vector3(76, -40, 0), "arm_lo_R": Vector3(0, 0, 26), "arm_up_L": Vector3(-76, -26, 0), "arm_lo_L": Vector3(0, 0, -16),
			"th_L": Vector3(0, -28, 0), "sh_L": Vector3(0, 14, 0), "th_R": Vector3(0, 20, 0), "sh_R": Vector3(0, 14, 0)}],
	"strike_heavy": [   # one-handed overhead slam; wings flare as the counterweight, the free arm swings back
		{"root": Vector3(-0.10, -0.18, 0), "spine": Vector3(0, -16, -24), "chest": Vector3(0, -14, -16), "hips": Vector3(0, 0, -20),
			"arm_up_R": Vector3(-52, -18, 0), "arm_lo_R": Vector3(0, 0, 58), "arm_up_L": Vector3(-34, 44, 0), "arm_lo_L": Vector3(0, 0, -20),
			"wing_L": Vector3(46, 0, 0), "wing_R": Vector3(-46, 0, 0), "wing2_L": Vector3(24, 0, 0), "wing2_R": Vector3(-24, 0, 0),
			"th_L": Vector3(0, -28, 0), "sh_L": Vector3(0, 34, 0), "th_R": Vector3(0, 26, 0), "sh_R": Vector3(0, 40, 0), "head": Vector3(0, -6, 8)},
		{"root": Vector3(0.64, -0.30, 0), "spine": Vector3(0, 40, 18), "chest": Vector3(0, 30, 12), "hips": Vector3(0, 8, 16),
			"arm_up_R": Vector3(46, -52, 0), "arm_lo_R": Vector3(0, 0, 8), "arm_up_L": Vector3(-22, 62, 0), "arm_lo_L": Vector3(0, 0, -6),
			"wing_L": Vector3(10, 0, 0), "wing_R": Vector3(-10, 0, 0),
			"th_L": Vector3(0, -46, 0), "sh_L": Vector3(0, 26, 0), "th_R": Vector3(0, 36, 0), "sh_R": Vector3(0, 16, 0), "head": Vector3(0, -22, -6)},
		{"root": Vector3(0.40, -0.26, 0), "spine": Vector3(0, 30, 6), "chest": Vector3(0, 22, 4),
			"arm_up_R": Vector3(60, -34, 0), "arm_lo_R": Vector3(0, 0, 30), "arm_up_L": Vector3(-56, 20, 0), "arm_lo_L": Vector3(0, 0, -14),
			"th_L": Vector3(0, -34, 0), "sh_L": Vector3(0, 30, 0), "th_R": Vector3(0, 26, 0), "sh_R": Vector3(0, 24, 0)}],
	"grab": [   # the thorned left forearm hooks and drags (raptorial grab); the club stays ready in the right hand
		{"root": Vector3(-0.14, -0.12, 0), "spine": Vector3(0, 6, 18), "chest": Vector3(0, 4, 12),
			"arm_up_L": Vector3(-30, 36, 0), "arm_lo_L": Vector3(0, 0, -64), "th_L": Vector3(0, -14, 0), "sh_L": Vector3(0, 24, 0)},
		{"root": Vector3(0.5, -0.12, 0), "spine": Vector3(0, 22, -16), "chest": Vector3(0, 16, -12),
			"arm_up_L": Vector3(-74, -76, 0), "arm_lo_L": Vector3(0, 0, -6), "th_L": Vector3(0, -40, 0), "sh_L": Vector3(0, 12, 0), "head": Vector3(0, -18, 0)},
		{"root": Vector3(0.3, -0.08, 0), "spine": Vector3(0, 14, -4), "arm_up_L": Vector3(-76, -40, 0), "arm_lo_L": Vector3(0, 0, -30)}],
	"ability1": [   # Ghost: folds into a still branch (crouched, limbs crossed over the chest, wings shut), holds, then unfurls
		{"root": Vector3(-0.12, -0.2, 0), "spine": Vector3(0, 14, 0), "chest": Vector3(0, 10, 0), "head": Vector3(0, -12, 0),
			"arm_up_R": Vector3(78, -40, 0), "arm_lo_R": Vector3(0, 0, 70), "arm_up_L": Vector3(-80, -30, 0), "arm_lo_L": Vector3(0, 0, -50),
			"wing_L": Vector3(-6, 0, 0), "wing_R": Vector3(6, 0, 0), "th_L": Vector3(0, -22, 0), "sh_L": Vector3(0, 40, 0), "th_R": Vector3(0, 12, 0), "sh_R": Vector3(0, 38, 0)},
		{"root": Vector3(-0.05, -0.44, 0), "spine": Vector3(0, 30, 0), "chest": Vector3(0, 22, 0), "head": Vector3(0, -22, 0),
			"arm_up_R": Vector3(84, -66, 0), "arm_lo_R": Vector3(0, 0, 112), "arm_up_L": Vector3(-86, -52, 0), "arm_lo_L": Vector3(0, 0, -96),
			"wing_L": Vector3(-20, 0, 0), "wing_R": Vector3(20, 0, 0), "wing2_L": Vector3(-14, 0, 0), "wing2_R": Vector3(14, 0, 0),
			"th_L": Vector3(0, -34, 0), "sh_L": Vector3(0, 62, 0), "th_R": Vector3(0, -6, 0), "sh_R": Vector3(0, 58, 0)},
		{"root": Vector3(0.0, -0.18, 0), "spine": Vector3(0, 16, 0), "chest": Vector3(0, 12, 0),
			"arm_up_R": Vector3(76, -34, 0), "arm_lo_R": Vector3(0, 0, 56), "arm_up_L": Vector3(-78, -20, 0), "arm_lo_L": Vector3(0, 0, -30),
			"wing_L": Vector3(28, 0, 0), "wing_R": Vector3(-28, 0, 0), "th_L": Vector3(0, -12, 0), "sh_L": Vector3(0, 26, 0), "th_R": Vector3(0, 8, 0), "sh_R": Vector3(0, 24, 0)}],
	"ability2": [   # Ground Prep: club lifted one-handed overhead, driven into the earth while the free palm slaps down beside it
		{"root": Vector3(-0.10, -0.14, 0), "spine": Vector3(0, -14, -18), "chest": Vector3(0, -12, -12), "hips": Vector3(0, 0, -14),
			"arm_up_R": Vector3(-48, -20, 0), "arm_lo_R": Vector3(0, 0, 60), "arm_up_L": Vector3(-60, 22, 0), "arm_lo_L": Vector3(0, 0, -24),
			"wing_L": Vector3(36, 0, 0), "wing_R": Vector3(-36, 0, 0), "th_L": Vector3(0, -22, 0), "sh_L": Vector3(0, 28, 0), "th_R": Vector3(0, 22, 0), "sh_R": Vector3(0, 34, 0)},
		{"root": Vector3(0.38, -0.46, 0), "spine": Vector3(0, 44, 12), "chest": Vector3(0, 32, 8), "hips": Vector3(0, 8, 10), "head": Vector3(0, -26, 0),
			"arm_up_R": Vector3(40, -54, 0), "arm_lo_R": Vector3(0, 0, 8), "arm_up_L": Vector3(-56, -82, 0), "arm_lo_L": Vector3(0, 0, -6),
			"wing_L": Vector3(8, 0, 0), "wing_R": Vector3(-8, 0, 0), "th_L": Vector3(0, -48, 0), "sh_L": Vector3(0, 62, 0), "th_R": Vector3(0, 30, 0), "sh_R": Vector3(0, 40, 0)},
		{"root": Vector3(0.24, -0.36, 0), "spine": Vector3(0, 30, 4), "chest": Vector3(0, 22, 2),
			"arm_up_R": Vector3(56, -38, 0), "arm_lo_R": Vector3(0, 0, 28), "arm_up_L": Vector3(-68, -52, 0), "arm_lo_L": Vector3(0, 0, -14),
			"th_L": Vector3(0, -34, 0), "sh_L": Vector3(0, 46, 0), "th_R": Vector3(0, 24, 0), "sh_R": Vector3(0, 30, 0)}],
	"laststand": [   # Last Stand: crouches into himself, then arches and roars, wings thrown wide, the club driven skyward
		{"root": Vector3(-0.15, -0.34, 0), "spine": Vector3(0, 28, 0), "chest": Vector3(0, 20, 0), "head": Vector3(0, -22, 0),
			"arm_up_R": Vector3(80, -50, 0), "arm_lo_R": Vector3(0, 0, 100), "arm_up_L": Vector3(-84, -40, 0), "arm_lo_L": Vector3(0, 0, -80),
			"wing_L": Vector3(-8, 0, 0), "wing_R": Vector3(8, 0, 0), "th_L": Vector3(0, -30, 0), "sh_L": Vector3(0, 66, 0), "th_R": Vector3(0, 6, 0), "sh_R": Vector3(0, 60, 0)},
		{"root": Vector3(0.0, 0.06, 0), "spine": Vector3(0, -18, 0), "chest": Vector3(0, -16, 0), "head": Vector3(0, 16, 0),
			"arm_up_R": Vector3(-20, -30, 0), "arm_lo_R": Vector3(0, 0, 40), "arm_up_L": Vector3(-30, 10, 0), "arm_lo_L": Vector3(0, 0, -20),
			"wing_L": Vector3(72, 0, 0), "wing_R": Vector3(-72, 0, 0), "wing2_L": Vector3(40, 0, 0), "wing2_R": Vector3(-40, 0, 0),
			"th_L": Vector3(10, -6, 0), "sh_L": Vector3(0, 8, 0), "th_R": Vector3(-10, 6, 0), "sh_R": Vector3(0, 8, 0)},
		{"root": Vector3(0.0, -0.1, 0), "spine": Vector3(0, 6, 0), "chest": Vector3(0, 4, 0),
			"arm_up_R": Vector3(60, -30, 0), "arm_lo_R": Vector3(0, 0, 40), "arm_up_L": Vector3(-70, -20, 0), "arm_lo_L": Vector3(0, 0, -24),
			"wing_L": Vector3(34, 0, 0), "wing_R": Vector3(-34, 0, 0)}],
	"ability3": [   # Detain: the thorned left arm whips out and hooks the target, then drags it in; the club stays cocked on the shoulder
		{"root": Vector3(-0.2, -0.16, 0), "spine": Vector3(0, 6, 22), "chest": Vector3(0, 4, 16), "hips": Vector3(0, 2, 14),
			"arm_up_L": Vector3(-40, 44, 0), "arm_lo_L": Vector3(0, 0, -76), "arm_up_R": Vector3(-20, -8, 0), "arm_lo_R": Vector3(0, 0, 108),
			"wing_L": Vector3(34, 0, 0), "wing_R": Vector3(-34, 0, 0), "th_L": Vector3(0, -12, 0), "sh_L": Vector3(0, 26, 0), "th_R": Vector3(0, 22, 0), "sh_R": Vector3(0, 30, 0)},
		{"root": Vector3(0.62, -0.14, 0), "spine": Vector3(0, 24, -20), "chest": Vector3(0, 18, -14), "hips": Vector3(0, 6, -12), "head": Vector3(0, -20, 0),
			"arm_up_L": Vector3(-76, -84, 0), "arm_lo_L": Vector3(0, 0, -4), "arm_up_R": Vector3(-20, -8, 0), "arm_lo_R": Vector3(0, 0, 108),
			"wing_L": Vector3(40, 0, 0), "wing_R": Vector3(-40, 0, 0), "th_L": Vector3(0, -46, 0), "sh_L": Vector3(0, 14, 0), "th_R": Vector3(0, 30, 0), "sh_R": Vector3(0, 8, 0)},
		{"root": Vector3(0.2, -0.1, 0), "spine": Vector3(0, 12, -8), "chest": Vector3(0, 8, -6),
			"arm_up_L": Vector3(-60, -40, 0), "arm_lo_L": Vector3(0, 0, -50), "arm_up_R": Vector3(-24, -10, 0), "arm_lo_R": Vector3(0, 0, 104)}],
	"ability": [   # club braced on the shoulder, the left hand flicks / commands
		{"root": Vector3(-0.08, -0.1, 0), "spine": Vector3(0, 2, 10), "chest": Vector3(0, 0, 8),
			"arm_up_R": Vector3(-20, -8, 0), "arm_lo_R": Vector3(0, 0, 112), "arm_up_L": Vector3(-24, -20, 0), "arm_lo_L": Vector3(0, 0, -36),
			"wing_L": Vector3(24, 0, 0), "wing_R": Vector3(-24, 0, 0)},
		{"root": Vector3(0.22, -0.1, 0), "spine": Vector3(0, 12, -12), "chest": Vector3(0, 8, -8),
			"arm_up_R": Vector3(-20, -8, 0), "arm_lo_R": Vector3(0, 0, 112), "arm_up_L": Vector3(-60, -70, 0), "arm_lo_L": Vector3(0, 0, -4),
			"wing_L": Vector3(34, 0, 0), "wing_R": Vector3(-34, 0, 0)},
		{"root": Vector3(0.1, -0.06, 0), "spine": Vector3(0, 10, -4), "arm_up_L": Vector3(-72, -30, 0), "arm_lo_L": Vector3(0, 0, -20)}],
}

const GUARD := {
	"root": Vector3(0.06, -0.12, 0), "spine": Vector3(0, 12, 0), "chest": Vector3(0, 10, 0), "head": Vector3(0, -12, 0),
	"arm_up_R": Vector3(80, -58, 0), "arm_lo_R": Vector3(0, 0, 96), "arm_up_L": Vector3(-82, -36, 0), "arm_lo_L": Vector3(0, 0, -52),
	"wing_L": Vector3(52, 0, 0), "wing_R": Vector3(-52, 0, 0), "wing2_L": Vector3(26, 0, 0), "wing2_R": Vector3(-26, 0, 0),
	"th_L": Vector3(0, -22, 0), "sh_L": Vector3(0, 32, 0), "th_R": Vector3(0, 14, 0), "sh_R": Vector3(0, 28, 0),
}
const PARRY := {   # a short sweep of the club across the body: the guard snaps open to knock the blow aside, wings flare for balance
	"root": Vector3(0.12, -0.14, 0), "spine": Vector3(0, 10, -22), "chest": Vector3(0, 8, -16), "hips": Vector3(0, 2, -10), "head": Vector3(0, -12, 6),
	"arm_up_R": Vector3(70, -78, 0), "arm_lo_R": Vector3(0, 0, 34), "arm_up_L": Vector3(-70, -20, 0), "arm_lo_L": Vector3(0, 0, -30),
	"wing_L": Vector3(60, 0, 0), "wing_R": Vector3(-60, 0, 0), "wing2_L": Vector3(30, 0, 0), "wing2_R": Vector3(-30, 0, 0),
	"th_L": Vector3(0, -24, 0), "sh_L": Vector3(0, 30, 0), "th_R": Vector3(0, 16, 0), "sh_R": Vector3(0, 30, 0),
}
const DODGE_FWD := {   # a low dive through the opponent's reach: head down, club trailing, wings pinned
	"root": Vector3(0.55, -0.42, 0), "spine": Vector3(0, 42, 0), "chest": Vector3(0, 30, 0), "head": Vector3(0, -18, 0),
	"arm_up_L": Vector3(-60, 40, 0), "arm_lo_L": Vector3(0, 0, -10), "arm_up_R": Vector3(70, 30, 0), "arm_lo_R": Vector3(0, 0, 20),
	"wing_L": Vector3(-14, 0, 0), "wing_R": Vector3(14, 0, 0),
	"th_L": Vector3(0, -44, 0), "sh_L": Vector3(0, 54, 0), "th_R": Vector3(0, 28, 0), "sh_R": Vector3(0, 24, 0),
}
const DODGE_SIDE := {   # a sidestep to his left: torso leans away from the blow, the leading leg reaches out, the trailing knee folds; mirrored for the right
	"root": Vector3(0.0, -0.22, 0), "spine": Vector3(-24, 14, 8), "chest": Vector3(-16, 10, 6), "head": Vector3(10, -12, 0),
	"arm_up_L": Vector3(-86, -10, 0), "arm_lo_L": Vector3(0, 0, -10), "arm_up_R": Vector3(80, -30, 0), "arm_lo_R": Vector3(0, 0, 40),
	"wing_L": Vector3(30, 0, 0), "wing_R": Vector3(-8, 0, 0),
	"th_L": Vector3(26, -10, 0), "sh_L": Vector3(0, 28, 0), "th_R": Vector3(-8, 8, 0), "sh_R": Vector3(0, 56, 0),
}
const GUARDBREAK := {   # the guard is smashed open: both arms flung wide, the club knocked out of line, torso rocked back and the wings thrown open
	"root": Vector3(-0.22, -0.14, 0), "spine": Vector3(0, -14, 0), "chest": Vector3(0, -18, 0), "head": Vector3(0, 12, 0),
	"arm_up_R": Vector3(30, -20, 0), "arm_lo_R": Vector3(0, 0, 22), "arm_up_L": Vector3(-34, 24, 0), "arm_lo_L": Vector3(0, 0, -20),
	"wing_L": Vector3(64, 0, 0), "wing_R": Vector3(-64, 0, 0), "wing2_L": Vector3(34, 0, 0), "wing2_R": Vector3(-34, 0, 0),
	"th_L": Vector3(0, -22, 0), "sh_L": Vector3(0, 40, 0), "th_R": Vector3(0, 8, 0), "sh_R": Vector3(0, 30, 0),
}
const PARRIED := {   # his own swing is turned aside: the club arm thrown up and across, the body dragged round after it
	"root": Vector3(0.1, -0.1, 0), "spine": Vector3(0, 6, 26), "chest": Vector3(0, 4, 18), "head": Vector3(0, -8, 10),
	"arm_up_R": Vector3(-30, -86, 0), "arm_lo_R": Vector3(0, 0, 14), "arm_up_L": Vector3(-60, -40, 0), "arm_lo_L": Vector3(0, 0, -30),
	"wing_L": Vector3(30, 0, 0), "wing_R": Vector3(-30, 0, 0),
	"th_L": Vector3(0, -30, 0), "sh_L": Vector3(0, 24, 0), "th_R": Vector3(0, 18, 0), "sh_R": Vector3(0, 30, 0),
}
const SALUTE := {   # the stare-down before a bout: the club held upright before the face like a sergeant's salute, head level, wings tucked
	"root": Vector3(0.0, -0.02, 0), "spine": Vector3(0, 5, 0), "chest": Vector3(0, 3, 0), "head": Vector3(0, -2, 0),
	"arm_up_R": Vector3(40, -78, 0), "arm_lo_R": Vector3(0, 0, 112), "arm_up_L": Vector3(-76, -10, 0), "arm_lo_L": Vector3(0, 0, -14),
	"th_L": Vector3(0, -2, 0), "sh_L": Vector3(0, 6, 0), "th_R": Vector3(0, 6, 0), "sh_R": Vector3(0, 8, 0),
}
const WIN := {   # victory: the club hoisted overhead in one fist, wings spread wide, chin up
	"root": Vector3(0.0, 0.0, 0), "spine": Vector3(0, 0, 0), "chest": Vector3(0, -4, 0), "head": Vector3(0, 8, 0),
	"arm_up_R": Vector3(-30, -26, 0), "arm_lo_R": Vector3(0, 0, 70), "arm_up_L": Vector3(-82, 10, 0), "arm_lo_L": Vector3(0, 0, -12),
	"wing_L": Vector3(50, 0, 0), "wing_R": Vector3(-50, 0, 0), "wing2_L": Vector3(28, 0, 0), "wing2_R": Vector3(-28, 0, 0),
	"th_L": Vector3(6, -4, 0), "sh_L": Vector3(0, 6, 0), "th_R": Vector3(-6, 4, 0), "sh_R": Vector3(0, 8, 0),
}
const DODGE := {   # a fold: collapse into a thin rod and slide, wings snapped shut
	"root": Vector3(-0.6, -0.16, 0), "spine": Vector3(0, 24, 0), "chest": Vector3(0, 16, 0), "head": Vector3(0, -14, 0),
	"arm_up_L": Vector3(-86, -4, 0), "arm_lo_L": Vector3(0, 0, -8), "arm_up_R": Vector3(84, -10, 0), "arm_lo_R": Vector3(0, 0, 14),
	"wing_L": Vector3(-16, 0, 0), "wing_R": Vector3(16, 0, 0),
	"th_L": Vector3(0, -22, 0), "sh_L": Vector3(0, 46, 0), "th_R": Vector3(0, -12, 0), "sh_R": Vector3(0, 44, 0),
}
const HIT := {
	"root": Vector3(-0.12, -0.04, 0), "spine": Vector3(0, -18, 8), "chest": Vector3(0, -14, 6), "neck": Vector3(0, 8, 0), "head": Vector3(0, 10, -8),
	"arm_up_L": Vector3(-58, 22, 0), "arm_up_R": Vector3(56, 12, 0), "wing_L": Vector3(20, 0, 0), "wing_R": Vector3(-20, 0, 0),
	"th_L": Vector3(0, -4, 0), "sh_L": Vector3(0, 22, 0), "th_R": Vector3(0, 12, 0), "sh_R": Vector3(0, 24, 0),
}
const STAGGER := {
	"root": Vector3(0.04, -0.26, 0), "spine": Vector3(0, 34, 6), "chest": Vector3(0, 26, 4), "head": Vector3(0, -6, 0),
	"arm_up_R": Vector3(86, -14, 0), "arm_lo_R": Vector3(0, 0, 6), "arm_up_L": Vector3(-70, -18, 0), "arm_lo_L": Vector3(0, 0, -30),
	"th_L": Vector3(0, -30, 0), "sh_L": Vector3(0, 52, 0), "th_R": Vector3(0, -14, 0), "sh_R": Vector3(0, 46, 0),
}
const GETUP := {   # half-way up from a knockdown: on hands and one knee, club planted like a crutch, head still down
	"root": Vector3(-0.35, -0.72, 0), "hips": Vector3(0, -34, 0), "spine": Vector3(0, 44, 0), "chest": Vector3(0, 22, 0), "head": Vector3(0, -18, 0),
	"arm_up_L": Vector3(-62, -66, 0), "arm_lo_L": Vector3(0, 0, -8), "arm_up_R": Vector3(60, -62, 0), "arm_lo_R": Vector3(0, 0, 12),
	"wing_L": Vector3(30, 0, 0), "wing_R": Vector3(-30, 0, 0),
	"th_L": Vector3(0, -58, 0), "sh_L": Vector3(0, 100, 0), "th_R": Vector3(0, 10, 0), "sh_R": Vector3(0, 70, 0),
}
const KO := {
	"root": Vector3(-0.9, -1.35, 0), "hips": Vector3(0, -84, 0), "spine": Vector3(0, -10, 0), "head": Vector3(0, 12, 0),
	"arm_up_L": Vector3(-30, 10, 0), "arm_up_R": Vector3(30, 10, 0), "wing_L": Vector3(34, 0, 0), "wing_R": Vector3(-34, 0, 0),
	"th_L": Vector3(0, -6, 0), "sh_L": Vector3(0, 26, 0), "th_R": Vector3(0, -2, 0), "sh_R": Vector3(0, 30, 0),
}

static func merged(base: Dictionary, over: Dictionary) -> Dictionary:
	var d := base.duplicate()
	for k in over:
		d[k] = over[k]
	return d

static func compile(p: Dictionary) -> Dictionary:
	var d := p.duplicate()
	d.erase("root")
	return d

static func root_of(p: Dictionary) -> Vector3:
	return p.get("root", Vector3.ZERO)

static func mix(a: Dictionary, b: Dictionary, w: float) -> Dictionary:
	var out := {}
	for k in a:
		out[k] = (a[k] as Vector3).lerp(b.get(k, Vector3.ZERO), w)
	for k in b:
		if not out.has(k):
			out[k] = Vector3.ZERO.lerp(b[k], w)
	return out

static func add(a: Dictionary, b: Dictionary) -> Dictionary:
	var out := a.duplicate()
	for k in b:
		out[k] = (out.get(k, Vector3.ZERO) as Vector3) + (b[k] as Vector3)
	return out

static func _full(over: Dictionary) -> Dictionary:
	return merged(IDLE, over)

static func _lerp_pose(a: Dictionary, b: Dictionary, w: float) -> Dictionary:
	var r := mix(compile(a), compile(b), w)
	r["root"] = root_of(a).lerp(root_of(b), w)
	return r

static func _out_back(t: float) -> float:
	var c := 1.4
	return 1.0 + (c + 1.0) * pow(t - 1.0, 3.0) + c * pow(t - 1.0, 2.0)

static func _out(t: float, p: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), p)

static func _result(p: Dictionary) -> Dictionary:
	return {"bones": compile(p), "root": root_of(p)}

## action: sim action name, frame: frames into the action, tm: Vector3i(startup, active, recovery), walk_t: walk phase, t: seconds.
## side: velocity to the critter's left in walk-speed units (negative = right); won: the bout is over and this fighter stands.
static func evaluate(action: String, frame: int, tm: Vector3i, walk_t: float, t: float, vit: float, spd := 1.0, fwd := 1.0, side := 0.0, mood := "") -> Dictionary:
	var idle := _idle(t, vit)
	if mood == "intro" and action in ["idle", "walk", "guard"]:
		var ip := _lerp_pose(idle, _full(SALUTE), 1.0)
		ip["wing_L"] = Vector3(10.0 + 2.0 * sin(t * 1.2), 0, 0)
		ip["wing_R"] = Vector3(-10.0 - 2.0 * sin(t * 1.2 + 0.7), 0, 0)
		return _result(ip)
	if mood == "won" and action in ["idle", "walk", "guard"]:
		var wp := _lerp_pose(idle, _full(WIN), 1.0)
		wp["wing_L"] = (wp["wing_L"] as Vector3) + Vector3(3.0 * sin(t * 1.6), 0, 0)
		wp["wing_R"] = (wp["wing_R"] as Vector3) - Vector3(3.0 * sin(t * 1.6 + 0.8), 0, 0)
		return _result(wp)
	match action:
		"walk":
			return _result(_walk(idle, walk_t, spd, fwd, side))
		"strike_light", "strike_heavy", "grab", "ability1", "ability2", "ability3", "laststand":
			var key := action if STYLES.has(action) else "ability"
			return _result(_attack(idle, STYLES[key], frame, tm))
		"guard":
			return _result(_lerp_pose(idle, _full(GUARD), _out(float(frame + 1) / 4.0, 2.0)))
		"parry":
			var snap := _lerp_pose(_full(GUARD), _full(PARRY), _out(float(frame + 1) / 3.0, 3.0))
			return _result(_lerp_pose(snap, _full(GUARD), smoothstep(8.0, 20.0, float(frame))))
		"dodge":
			var d := maxi(1, tm.x + tm.y)
			var u := clampf(float(frame) / float(d), 0.0, 1.0)
			var tgt := _full(DODGE)                          # backwards fold by default
			var dv := Vector2(fwd, side)
			if dv.length() > 0.25:
				var n := dv.normalized()
				var wf := maxf(n.x, 0.0)
				var wb := maxf(-n.x, 0.0)
				tgt = _lerp_pose(_full(DODGE), _full(DODGE_FWD), wf / maxf(wf + wb, 0.001))
				var sp := _full(DODGE_SIDE) if side >= 0.0 else _mirror(_full(DODGE_SIDE))
				tgt = _lerp_pose(tgt, sp, smoothstep(0.2, 0.9, absf(n.y)))
			var back := _lerp_pose(tgt, idle, _out((float(frame) - float(d)) / maxf(1.0, float(tm.z)), 1.8) if frame > d else 0.0)
			return _result(_lerp_pose(idle, back, _out(u * 3.0, 2.0)))
		"hit", "clash":
			var hp := _lerp_pose(_full(HIT), idle, _out(float(frame) / maxf(10.0, float(tm.y + tm.z)), 2.0))
			return _result(_lean(hp, side, 1.0 - clampf(float(frame) / 14.0, 0.0, 1.0)))
		"stagger":
			var base_st := _full(STAGGER)
			if mood.ends_with("|guardbreak"):
				base_st = _full(GUARDBREAK)
			elif mood.ends_with("|parried"):
				base_st = _full(PARRIED)
			var sp2 := _lerp_pose(idle, base_st, _out(float(frame + 1) / 6.0, 2.0))
			return _result(_lean(sp2, side, 0.7))
		"ko", "knockdown":
			var u2 := clampf(float(frame) / maxf(1.0, float(tm.x + tm.y) * 0.6), 0.0, 1.0)
			var p := _lerp_pose(_full(STAGGER), _full(KO), _out(u2, 3.0))
			if action == "knockdown" and frame > tm.x + tm.y:
				var g := clampf(float(frame - tm.x - tm.y) / maxf(1.0, float(tm.z)), 0.0, 1.0)        # get-up: roll onto hands and a knee, then stand tall with a shudder of the wings
				if g < 0.55:
					p = _lerp_pose(_full(KO), _full(GETUP), _out(g / 0.55, 2.0))
				else:
					p = _lerp_pose(_full(GETUP), idle, smoothstep(0.0, 1.0, (g - 0.55) / 0.45))
					p["wing_L"] = (p["wing_L"] as Vector3) + Vector3(10.0 * sin(g * 40.0) * (1.0 - g), 0, 0)
			return _result(p)
	return _result(idle)

static func _idle(t: float, vit: float) -> Dictionary:
	var p := IDLE.duplicate()
	var br := sin(t * 2.1)
	p["spine"] = (p["spine"] as Vector3) + Vector3(0, 1.4 * br + (1.0 - vit) * 10.0, 0)
	p["chest"] = (p["chest"] as Vector3) + Vector3(0, 1.0 * br, 0)
	p["head"] = (p["head"] as Vector3) + Vector3(0, -0.8 * br, 1.5 * sin(t * 0.7))
	p["arm_up_L"] = (p["arm_up_L"] as Vector3) + Vector3(0.8 * br, 0, 0)
	p["wing_L"] = Vector3(4.0 + 2.0 * sin(t * 1.3) + 9.0 * pow(maxf(0.0, sin(t * 0.83)), 12.0), 0, 0)         # an occasional single-wing twitch
	p["wing_R"] = Vector3(-4.0 - 2.0 * sin(t * 1.3 + 1.0) - 7.0 * pow(maxf(0.0, sin(t * 0.61 + 2.0)), 14.0), 0, 0)
	var shift := sin(t * 0.43)                                                                 # slow weight shift from foot to foot, the hips and torso counter-rolling
	p["hips"] = (p["hips"] as Vector3) + Vector3(1.8 * shift, 0, 0)
	p["spine"] = (p["spine"] as Vector3) + Vector3(-1.2 * shift, 0, 0.8 * sin(t * 0.29))
	p["th_L"] = (p["th_L"] as Vector3) + Vector3(2.0 * shift, 0, 0)
	p["th_R"] = (p["th_R"] as Vector3) + Vector3(2.0 * shift, 0, 0)
	var glance := smoothstep(0.55, 0.95, sin(t * 0.21 + 1.0))                                  # now and then the head tracks something off to one side, then returns
	p["head"] = (p["head"] as Vector3) + Vector3(0, 0, 14.0 * glance * sin(t * 0.37))
	return p

## Gait: a deliberate STALK at walking speed (long stride led by the hips, knees lifted, torso nearly still, club carried low), leaning into a RUN as
## speed approaches its maximum, and a guarded BACKPEDAL (short stride, upper body upright, club raised) when moving against the facing direction.
## spd = speed / walk speed (0..1.25), fwd = velocity along the facing / walk speed (negative = backwards).
## Sideways reaction to a blow: the torso rolls and the head snaps away from the side he is knocked toward (side = velocity to his left, walk-speed units).
static func _lean(p: Dictionary, side: float, amount: float) -> Dictionary:
	var k := clampf(side, -1.2, 1.2) * amount
	if absf(k) < 0.02:
		return p
	var out := p.duplicate()
	out["spine"] = (out["spine"] as Vector3) + Vector3(20.0 * k, 0, 6.0 * k)
	out["chest"] = (out["chest"] as Vector3) + Vector3(14.0 * k, 0, 4.0 * k)
	out["head"] = (out["head"] as Vector3) + Vector3(-12.0 * k, 0, -16.0 * k)
	out["arm_up_L"] = (out["arm_up_L"] as Vector3) + Vector3(-10.0 * k, 0, 0)
	out["arm_up_R"] = (out["arm_up_R"] as Vector3) + Vector3(-10.0 * k, 0, 0)
	return out

## Left/right mirror of a pose: swaps the L/R bones, flips roll and yaw, keeps pitch; the root's forward offset stays.
static func _mirror(p: Dictionary) -> Dictionary:
	var out := {}
	for k in p:
		var v := p[k] as Vector3
		if k == "root":
			out[k] = v
			continue
		var nk: String = k
		if k.ends_with("_L"):
			nk = k.trim_suffix("_L") + "_R"
		elif k.ends_with("_R"):
			nk = k.trim_suffix("_R") + "_L"
		out[nk] = Vector3(-v.x, v.y, -v.z)
	return out

static func _walk(idle: Dictionary, ph: float, spd: float, fwd: float, side := 0.0) -> Dictionary:
	var amp := clampf(spd, 0.45, 1.25)
	var run := smoothstep(0.85, 1.2, spd)
	var back := smoothstep(0.1, 0.5, -fwd)
	var s := sin(ph)
	var c := cos(ph)
	var stride := (27.0 + 2.0 * run) * amp * (1.0 - 0.45 * back)
	var p := idle.duplicate()
	p["root"] = Vector3(0.03 * amp * (1.0 - back), -0.05 - 0.035 * absf(c) * amp - 0.03 * run, 0)
	p["hips"] = (p["hips"] as Vector3) + Vector3(0, 2.0 * run, 8.0 * s * amp)
	p["spine"] = (p["spine"] as Vector3) + Vector3(0, 5.0 * run * (1.0 - back) - 5.0 * back, -7.0 * s * amp)
	p["chest"] = (p["chest"] as Vector3) + Vector3(0, 3.0 * run * (1.0 - back), -5.0 * s * amp)
	p["head"] = (p["head"] as Vector3) + Vector3(0, -4.0 * run, 0)
	# legs: opposite phases; the knee lifts on the swing leg (max(0, cos) style), the stance leg stays straight
	var swing_l := maxf(0.0, -c)
	var swing_r := maxf(0.0, c)
	p["th_L"] = Vector3(0, -6.0 - stride * s, 0)
	p["sh_L"] = Vector3(0, 12.0 + (46.0 + 20.0 * run) * swing_l * amp, 0)
	p["th_R"] = Vector3(0, 8.0 + stride * s, 0)
	p["sh_R"] = Vector3(0, 14.0 + (46.0 + 20.0 * run) * swing_r * amp, 0)
	# arms: the free hand counter-swings (pumps in a run), the club arm carries low and steady, raised into a guard when backing off
	var al := p["arm_up_L"] as Vector3
	p["arm_up_L"] = Vector3(al.x, al.y + (14.0 + 22.0 * run) * s * amp, al.z)
	p["arm_lo_L"] = (p["arm_lo_L"] as Vector3) + Vector3(0, 0, -20.0 * run)
	var ar := p["arm_up_R"] as Vector3
	p["arm_up_R"] = Vector3(ar.x, ar.y - 6.0 * s * amp + 10.0 * back, ar.z)
	p["arm_lo_R"] = (p["arm_lo_R"] as Vector3) + Vector3(0, 0, 20.0 * back)
	for wn in ["wing_L", "wing_R"]:
		var wv := p.get(wn, Vector3.ZERO) as Vector3
		p[wn] = wv + Vector3((14.0 * run + 10.0 * back) * (1.0 if wn == "wing_L" else -1.0), 0, 0)    # wings lift a little with effort
	# strafe: squared up and low, the club hand high in a guard, legs stepping sideways (the leading leg reaches out, the trailing leg crosses behind)
	var sk := smoothstep(0.25, 0.65, absf(side) / maxf(spd, 0.01)) * smoothstep(0.15, 0.4, spd)
	if sk > 0.01:
		var sg := signf(side)
		var lead := 0.5 + 0.5 * s
		var strafe := _full(GUARD)
		strafe["root"] = Vector3(0.0, -0.16 - 0.03 * absf(c), 0)
		strafe["hips"] = Vector3(0, 4, 0)
		strafe["spine"] = Vector3(-5.0 * sg * s, 10, 0)
		var lead_leg := "th_L" if sg > 0.0 else "th_R"
		var trail_leg := "th_R" if sg > 0.0 else "th_L"
		strafe[lead_leg] = Vector3(sg * (10.0 + 16.0 * lead), -6, 0)
		strafe[trail_leg] = Vector3(-sg * (4.0 + 6.0 * (1.0 - lead)), 10, 0)
		strafe["sh_L"] = Vector3(0, 26.0 + 18.0 * maxf(0.0, -c), 0)
		strafe["sh_R"] = Vector3(0, 26.0 + 18.0 * maxf(0.0, c), 0)
		p = _lerp_pose(p, strafe, sk)
	return p

static func _attack(idle: Dictionary, st: Array, frame: int, tm: Vector3i) -> Dictionary:
	var ant := _full(st[0])
	var hit := _full(st[1])
	var rec := _full(st[2])
	var s := maxi(1, tm.x)
	var a := maxi(1, tm.y)
	var r := maxi(1, tm.z)
	if frame < s:                                   # anticipation: slow in, hold, a tremble of held strength just before the strike
		var u := float(frame) / float(s)
		var w := u * u * (3.0 - 2.0 * u)
		w = pow(w, 1.35)
		var p := _lerp_pose(idle, ant, w)
		if u > 0.7:
			var tr := (u - 0.7) / 0.3
			p["spine"] = (p["spine"] as Vector3) + Vector3(0, 0, sin(float(frame) * 2.3) * 1.6 * tr)
		return p
	if frame < s + a:                               # impact: snap through the pose with overshoot
		var u2 := float(frame - s) / float(a)
		return _lerp_pose(ant, hit, _out_back(clampf(u2 * 2.0, 0.0, 1.0)))
	var u3 := float(frame - s - a) / float(r)       # recovery: settle out of the lunge, then return to stance
	if u3 < 0.6:
		return _lerp_pose(hit, rec, _out(u3 / 0.6, 2.2))
	return _lerp_pose(rec, idle, _out((u3 - 0.6) / 0.4, 1.6))
