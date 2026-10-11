class_name Rack
extends RefCounted
## The Rack: up to 7 jar slots (GDD 4). Slots hold living CritterInstance or null. Slot indices are stable
## (removing a critter leaves its jar empty) so the Rack screen layout does not jump.

const CAPACITY := 7

var slots: Array = []


func _init() -> void:
	slots.resize(CAPACITY)
	slots.fill(null)


func count() -> int:
	var n := 0
	for s in slots:
		if s != null:
			n += 1
	return n


func is_full() -> bool:
	return count() >= CAPACITY


## Puts the critter in the first empty jar. Returns the slot index or -1 when the Rack is full.
func add(c: CritterInstance) -> int:
	for i in CAPACITY:
		if slots[i] == null:
			slots[i] = c
			return i
	return -1


func slot_of(uid: String) -> int:
	for i in CAPACITY:
		if slots[i] != null and slots[i].uid == uid:
			return i
	return -1


func get_by_uid(uid: String) -> CritterInstance:
	var i := slot_of(uid)
	return slots[i] if i >= 0 else null


func remove(uid: String) -> CritterInstance:
	var i := slot_of(uid)
	if i < 0:
		return null
	var c: CritterInstance = slots[i]
	slots[i] = null
	return c


func living() -> Array:
	return slots.filter(func(s): return s != null)


func to_array() -> Array:
	return slots.map(func(s): return s.to_dict() if s != null else null)


static func from_array(a: Array) -> Rack:
	var r := Rack.new()
	for i in mini(a.size(), CAPACITY):
		if a[i] is Dictionary:
			var c := CritterInstance.from_dict(a[i])
			if c.alive:
				r.slots[i] = c
	return r
