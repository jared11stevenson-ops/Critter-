extends RefCounted
## Presentation reactions to sim events (hit flash, squash kick, shake, sparks, expression flashes, impact frames).
## Events are about the rig's own fighter; see critter_rig.gd header for routing.

static func _local_pos(rig: Node3D, ev: Dictionary) -> Vector3:
	var wp = ev.get("world_pos", null)   # optional Vector3 impact point; otherwise the chest, front side
	if wp is Vector3:
		return rig.to_local(wp)
	return Vector3(0.45 * rig._facing, 0.95, 0.5)

static func play(rig: Node3D, ev: Dictionary) -> void:
	var fx = rig.fx
	var face = rig.face
	var pal: Dictionary = rig.palette
	var t: String = str(ev.get("type", ""))
	var heavy: bool = bool(ev.get("heavy", false))
	match t:
		"hit":
			fx.flash()
			rig._kick(0.28 if not heavy else 0.45)
			rig._shake_f = 8 if not heavy else 14
			rig._shake_amp = 1.0 if not heavy else 2.2
			fx.hit_spark(_local_pos(rig, ev), 1.5 if not heavy else 2.4, pal["glow"].lerp(Color(1.0, 0.95, 0.7), 0.5))
			if face:
				face.flash_expression("hurt", 0.5)
			if heavy:
				fx.impact_frame()
		"block":
			rig._kick(0.1)
			rig._shake_f = 4; rig._shake_amp = 0.5
			fx.hit_spark(_local_pos(rig, ev), 0.7, Color(0.8, 0.95, 1.0))
		"parry":
			fx.flash()
			rig._kick(-0.12)
			fx.hit_spark(_local_pos(rig, ev), 1.5, Color(1.0, 0.95, 0.6))
			fx.impact_frame()
			if face:
				face.flash_expression("grin", 0.8)
		"clash":
			rig._kick(0.2)
			rig._shake_f = 6; rig._shake_amp = 1.2
			fx.hit_spark(_local_pos(rig, ev), 1.3, Color(1.0, 1.0, 1.0))
		"grab":
			if face:
				face.flash_expression("grin", 0.8)
			rig._kick(0.15)
		"dodge":
			rig._kick(-0.2)
		"stagger":
			if face:
				face.flash_expression("hurt", 0.8)
			rig._shake_f = 10; rig._shake_amp = 1.4
		"tell":
			rig._kick(-0.1)
			fx.boost_glow(1.2)
		"ringout":
			if face:
				face.flash_expression("scared", 2.0)
		"ko":
			fx.impact_frame()
			fx.flash()
			if face:
				face.flash_expression("dying", 10.0)
		"laststand":
			fx.flash()
			fx.boost_glow(2.4)
			rig._kick(-0.25)
			rig._shake_f = 18; rig._shake_amp = 1.0
			if face:
				face.flash_expression("angry", 3.0)
		"yield":
			if face:
				face.flash_expression("hurt", 1.2)
	if face:
		face.update(0.0)
