extends RefCounted
## World entity spawned by abilities: projectile, zone (trap / DOT / field), phantom (summon).
var kind := "proj"
var owner := 0
var tag := ""
var move_id := ""
var pos := Vector2.ZERO
var dir := Vector2.RIGHT
var speed := 0.0            # m per tick
var radius := 0.5
var life := 60
var hit: Dictionary = {}
var pierce := false
var once := false
var dps := 0.0
var affect := "enemy"       # enemy | self | both
var on_enter: Dictionary = {}
var buff: Dictionary = {}
var timer := 0
var interval := 30
var reach := 1.5
var arm := 0                # frames before a trap becomes active
