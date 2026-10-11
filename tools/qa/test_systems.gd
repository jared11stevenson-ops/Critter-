extends Node
## Headless unit tests for the Ledger / Promises / Bonds / Reactions / Rivals systems.
## Run: godot --headless --path . res://tools/qa/test_systems.tscn -- test_systems
var runner: Variant = null   # region-runner host interface (the NPC test)
var passed := 0
var failed := 0

func ok(cond: bool, label: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("[TEST] FAIL ", label)

func _ready() -> void:
	await get_tree().process_frame
	_test_ledger_basics()
	_test_opinion()
	_test_promise_loophole()
	_test_promise_kept_and_broken()
	_test_bond_zephyr()
	_test_reactions()
	_test_flag_hooks_and_debrief()
	_test_persistence()
	_test_rivals()
	_test_combat_feel()
	_test_hub_flow()
	_test_hud_flow()
	await _test_npcs()
	_test_explore()
	await _test_explore_level()
	print("[TEST] pass=%d fail=%d" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)

func _test_combat_feel() -> void:
	var P := CombatTiming.Phase
	ok(CombatTiming.phase_at(0.0, 0.1, 0.08, 0.25) == P.WINDUP, "phase windup at 0")
	ok(CombatTiming.phase_at(0.1, 0.1, 0.08, 0.25) == P.ACTIVE, "phase active at windup edge")
	ok(CombatTiming.phase_at(0.2, 0.1, 0.08, 0.25) == P.RECOVER, "phase recover")
	ok(CombatTiming.phase_at(0.5, 0.1, 0.08, 0.25) == P.DONE, "phase done")
	ok(CombatTiming.buffer_valid(1.0, 0.8, 0.28) and not CombatTiming.buffer_valid(1.0, 0.6, 0.28), "buffer window")
	ok(not CombatTiming.buffer_valid(0.0, -1.0, 0.28), "buffer rejects unset press (-1)")
	# aim stickiness: a current target 1.0 m farther still wins with the default bonus, but not at 3 m farther
	var bonus := Balance.f("global.autoaim_stick", 1.6)
	ok(CombatTiming.aim_score(5.0, 0.0, false, true, bonus) < CombatTiming.aim_score(4.0, 0.0, false, false, bonus), "sticky target keeps lock vs +1 m rival")
	ok(CombatTiming.aim_score(8.0, 0.0, false, true, bonus) > CombatTiming.aim_score(4.0, 0.0, false, false, bonus), "sticky bonus is bounded")
	ok(CombatTiming.aim_score(3.0, 0.0, true, false, bonus) > CombatTiming.aim_score(3.0, 0.0, false, false, bonus), "objects rank behind creatures")
	# lunge never overshoots the target
	ok(is_equal_approx(CombatTiming.lunge_clamp(1.6, 5.0), 1.6), "lunge unclamped when far")
	ok(is_equal_approx(CombatTiming.lunge_clamp(1.6, 1.2), 0.3), "lunge stops short of target")
	ok(CombatTiming.lunge_clamp(1.6, 0.2) == 0.0, "no lunge when touching")
	ok(is_equal_approx(CombatTiming.lunge_clamp(1.0, -1.0), 1.0), "no target -> full lunge")
	ok(CombatTiming.urgency(0.5) == 0.0 and is_equal_approx(CombatTiming.urgency(1.0), 1.0), "telegraph urgency ramps 0..1")
	ok(CombatTiming.urgency(0.825) > 0.45 and CombatTiming.urgency(0.825) < 0.55, "telegraph urgency midpoint")
	ok(CombatTiming.is_perfect_dodge("dash", 0.1) and not CombatTiming.is_perfect_dodge("dash", 0.0) and not CombatTiming.is_perfect_dodge("normal", 0.3), "perfect dodge only inside dash i-frames")
	# tuning lives in balance.json
	for k in ["input_buffer", "autoaim_stick", "autoaim_lock_time", "kick_light", "kick_heavy", "kick_hurt", "kick_decay", "perfect_dodge_scale", "perfect_dodge_time", "telegraph_urgent_from"]:
		ok(Balance.v("global." + k, null) != null, "balance global.%s present" % k)
	ok(Balance.f("global.input_buffer", 0.0) > 0.1 and Balance.f("global.input_buffer", 0.0) < 0.6, "input buffer in a sane range")
	for ch in ["aruun", "cigarra"]:
		ok(Balance.f(ch + ".dash_iframes", 0.0) >= 0.2 and Balance.f(ch + ".dash_iframes", 0.0) <= Balance.f(ch + ".dash_time", 1.0) + 0.1, "%s dash i-frames fit the dash" % ch)
	# every kit ability has a vector icon and a distinct accent
	var ids: Array = ["reaching_strike", "gravity_pull", "beetle_rage", "premonition", "false_memory", "brain_skip", "aruun_combo", "bad_thought", "dash", "scan"]
	var seen := {}
	for id in ids:
		ok(AbilityIcons.has_vector(id), "vector icon for %s" % id)
		var col := AbilityIcons.accent(id)
		ok(not seen.has(col.to_html()), "icon accent distinct: %s" % id)
		seen[col.to_html()] = true

func fresh() -> void:
	Ledger.reset()
	Rivals.reset()
	GameState.flags = {}

func _test_ledger_basics() -> void:
	fresh()
	ok(Ledger.bond_stage("aruun") == "bonded" and Ledger.bond_stage("cigarra") == "bonded", "initial bonds")
	var e1 := Ledger.record("harmed", "player", "dust_grazer_herd", ["harm_wildlife"], {}, 3, "red_reaches")
	Ledger.record("helped", "player", "plate_beetle_herd", ["calmed_wildlife"], {}, 2, "red_reaches")
	ok(Ledger.count({"type": "harmed"}) == 1, "count by type")
	ok(Ledger.count({"tag": "calmed_wildlife", "region": "red_reaches"}) == 1, "count by tag+region")
	ok(Ledger.last({"type": "harmed"}).get("id") == e1["id"], "last()")
	ok(Ledger.memory_of("dust_grazer_herd").size() == 1, "memory_of")
	ok(Ledger.exists({"type": "helped", "count_min": 1}) and not Ledger.exists({"type": "helped", "count_min": 2}), "count_min")
	ok(Ledger.check({"all": [{"event": {"type": "harmed"}}, {"none": {"type": "killed"}}]}), "spec all/none")
	ok(not Ledger.check({"not": {"event": {"type": "harmed"}}}), "spec not")

func _test_opinion() -> void:
	fresh()
	Ledger.record("harmed", "player", "dust_grazer_herd", ["harm_wildlife"], {}, 3)
	Ledger.record("chose", "player", "ochre_span", ["braced_structure"], {}, 5)
	ok(Ledger.opinion("aruun") == (-2.0 * 3.0 + 3.0 * 5.0), "aruun opinion math (+9)")
	ok(Ledger.opinion("dexter") == (-0.5 * 5.0), "dexter opinion math")
	Ledger.record("helped", "player", "x", ["spared"], {"witnesses": ["cigarra"]}, 2)
	ok(Ledger.opinion("zephyr") == 0.0 or Ledger.opinion("zephyr") == 0.0 + 0.5 * 0.0, "witness filter: zephyr did not see it")
	ok(Ledger.opinion_label(Ledger.opinion("aruun")) in ["trusting", "warm", "devoted"], "label positive")

func _test_promise_loophole() -> void:
	fresh()
	Ledger.make_promise("p1", "zephyr", "bring_both_home")
	ok(Ledger.promise_status("p1") == "open", "promise open")
	Ledger.begin_run("red_reaches")
	Ledger.record("party_wipe", "player", "", ["casualty"], {}, 3)   # both went down once, respawned
	Ledger.end_run(true)                                              # but everyone is conscious at the end
	ok(Ledger.promise_status("p1") == "loophole", "letter kept, spirit not -> loophole (got %s)" % Ledger.promise_status("p1"))
	ok(Ledger.opinion("zephyr") > Ledger.opinion("aruun") - 100.0, "sanity")
	# Zephyr rewards loopholes, Aruun does not
	var zeph := Ledger.opinion("zephyr")
	var aru := Ledger.opinion("aruun")
	ok(zeph > 0.0, "zephyr likes loophole (%f)" % zeph)
	ok(aru < 0.0, "aruun dislikes loophole (%f)" % aru)

func _test_promise_kept_and_broken() -> void:
	fresh()
	Ledger.make_promise("p2", "zephyr", "bring_both_home")
	Ledger.begin_run("red_reaches")
	Ledger.end_run(true)
	ok(Ledger.promise_status("p2") == "kept", "clean run -> kept")
	fresh()
	Ledger.make_promise("p3", "zephyr", "bring_both_home")
	Ledger.begin_run("red_reaches")
	Ledger.record("downed", "player", "aruun", ["casualty"], {}, 2)
	Ledger.end_run(false)
	ok(Ledger.promise_status("p3") == "broken", "nobody conscious, no spirit -> broken (got %s)" % Ledger.promise_status("p3"))
	ok(Ledger.opinion("zephyr") < -10.0, "broken promise is costly for zephyr")

func _test_bond_zephyr() -> void:
	fresh()
	ok(Ledger.bond_stage("zephyr") == "unmet", "zephyr unmet")
	Ledger.record("talked", "player", "zephyr", ["social"], {}, 1)
	ok(Ledger.bond_stage("zephyr") == "met", "talked -> met")
	Ledger.make_promise("zephyr_bring_both_home", "zephyr", "bring_both_home")
	ok(Ledger.bond_stage("zephyr") == "interested", "promise made -> interested (got %s)" % Ledger.bond_stage("zephyr"))
	Ledger.begin_run("red_reaches")
	Ledger.end_run(true)
	ok(Ledger.bond_stage("zephyr") == "bonded", "promise kept + opinion -> bonded (got %s)" % Ledger.bond_stage("zephyr"))
	fresh()
	Ledger.record("talked", "player", "zephyr", ["social"], {}, 1)
	Ledger.make_promise("zephyr_bring_both_home", "zephyr", "bring_both_home")
	Ledger.begin_run("red_reaches")
	Ledger.record("downed", "player", "aruun", ["casualty"], {}, 2)
	Ledger.end_run(false)
	ok(Ledger.bond_stage("zephyr") == "estranged", "broken promise -> estranged (got %s)" % Ledger.bond_stage("zephyr"))

func _test_reactions() -> void:
	fresh()
	ok(Ledger.take_reaction("aruun", "return").is_empty(), "no reaction yet")
	Ledger.record("harmed", "player", "dust_grazer_herd", ["harm_wildlife"], {}, 3)
	var r := Ledger.take_reaction("aruun", "return")
	ok(r.get("id") == "aruun_grazers", "reaction chosen from memory")
	ok(Ledger.take_reaction("aruun", "return").is_empty(), "once-only reaction not repeated")

func _test_flag_hooks_and_debrief() -> void:
	fresh()
	Ledger.begin_run("red_reaches")
	GameState.set_flag("grazers_harmed", true)
	GameState.set_flag("ochre_span", "braced")
	GameState.set_flag("promised_zephyr", true)
	ok(Ledger.count({"type": "harmed"}) == 1, "flag -> harmed event")
	ok(Ledger.count({"type": "chose", "tag": "braced_structure"}) == 1, "flag value -> chose event")
	ok(Ledger.promises.has("zephyr_bring_both_home"), "flag -> promise made")
	var lines := Ledger.debrief_lines()
	var joined: String = " ".join(PackedStringArray(lines))
	ok(joined.contains("Ochre Span is braced"), "debrief mentions the span (got: %s)" % joined)
	ok(joined.contains("Dust Grazer") or joined.contains("Dust grazer") or joined.contains("herd"), "debrief mentions grazers (got: %s)" % joined)
	ok(Ledger.opinion_shift_lines().size() >= 1, "opinion shift lines")

func _test_persistence() -> void:
	fresh()
	Ledger.record("harmed", "player", "x", ["harm_wildlife"], {}, 3)
	Ledger.make_promise("pp", "zephyr", "bring_both_home")
	var d := Ledger.to_dict()
	var json: Variant = JSON.parse_string(JSON.stringify(d))
	var n := Ledger.events.size()
	var t := Ledger.tick
	Ledger.reset()
	Ledger.from_dict(json)
	ok(Ledger.events.size() == n and Ledger.tick == t, "roundtrip counts")
	ok(Ledger.promise_status("pp") == "open", "roundtrip promise")
	Ledger.record("helped", "player", "y", ["spared"], {}, 1)
	ok(Ledger.events[Ledger.events.size() - 1]["id"] > Ledger.events[Ledger.events.size() - 2]["id"], "ids keep increasing after load")

func _test_rivals() -> void:
	fresh()
	var a := Rivals.spawn("survey_chief", "red_reaches", 123)
	var b := Rivals.spawn("survey_chief", "red_reaches", 123)
	ok(a["name"] == b["name"] and a["traits"] == b["traits"], "deterministic spawn")
	var o := Rivals.get_rival("foreman_orrin")
	ok(o["name"] == "Hale Orrin" and "meticulous" in o["traits"], "authored rival")
	ok(Rivals.active_in("red_reaches").size() >= 2, "active_in region")
	ok(Rivals.greeting("foreman_orrin")["text"].contains("Hale Orrin"), "first greeting")
	# fight: lean on premonition + reaching strike
	Rivals.encounter_begin("foreman_orrin")
	for i in 5:
		Events.ability_used.emit("cigarra", "premonition")
	for i in 2:
		Events.ability_used.emit("aruun", "reaching_strike")
	var r := Rivals.encounter_end("foreman_orrin", "escaped", ["reaching_strike"])
	ok("erratic_timing" in r["adaptations"], "adapts to dominant ability")
	ok(not r["scars"].is_empty() and r["state"] == "escaped", "scar + escaped")
	var prof := Rivals.behavior_profile("foreman_orrin")
	ok("erratic_timing" in prof["tactics"] and "call_drones" in prof["tactics"] and "plans_ahead" in prof["tactics"], "behavior profile merges base+trait+adapt")
	var g: String = Rivals.greeting("foreman_orrin")["text"]
	ok(g.contains("decide until I move") or g.contains("pauldron") or g.contains("visor"), "greeting remembers (got: %s)" % g)
	ok(Ledger.count({"type": "rival_resolved", "tag": "rival_escaped"}) == 1, "ledger knows the rival escaped")
	# resolution options
	var ids := []
	for opt in Rivals.resolution_options("foreman_orrin"):
		ids.append(opt["id"])
	ok("fight" in ids and "release" in ids and "negotiate" in ids and not ("expose" in ids) and not ("bond" in ids), "options: negotiate yes (meticulous), expose/bond no (got %s)" % str(ids))
	Ledger.record("discovered", "player", "permit_forgery", ["evidence", "discovery"], {}, 2)
	var ids2 := []
	for opt in Rivals.resolution_options("foreman_orrin"):
		ids2.append(opt["id"])
	ok("expose" in ids2, "evidence unlocks expose")
	# poacher: release then bond
	var pv := Rivals.get_rival("poacher_vesk")
	var ids3 := []
	for opt in Rivals.resolution_options("poacher_vesk"):
		ids3.append(opt["id"])
	ok(not ("bond" in ids3), "bond locked until released once")
	Rivals.encounter_begin("poacher_vesk")
	Rivals.encounter_end("poacher_vesk", "released")
	Rivals.get_rival("poacher_vesk")["state"] = "active"
	var ids4 := []
	for opt in Rivals.resolution_options("poacher_vesk"):
		ids4.append(opt["id"])
	ok("bond" in ids4, "bond unlocked after release (got %s)" % str(ids4))
	ok(Ledger.opinion("aruun") > 0.0 and Ledger.opinion("mara") > 0.0, "sparing a rival pleases aruun & mara")
	# persistence of rivals
	var d := Rivals.to_dict()
	var json: Variant = JSON.parse_string(JSON.stringify(d))
	Rivals.reset()
	Rivals.from_dict(json)
	ok(Rivals.get_rival("foreman_orrin")["encounters"] == 1 and "erratic_timing" in Rivals.get_rival("foreman_orrin")["adaptations"], "rival roundtrip")

## Red Reaches NPCs (NpcLife + canon NPC file): every canon NPC spawns, talk() follows meet -> quest offer -> repeat, rec:/offer:
## events act on the Ledger / quest hand-off, registry covers every NPC.
func _test_npcs() -> void:
	fresh()
	GameState.items = {}
	var host := Node3D.new()
	add_child(host)
	var dlg := DialogueRunner.new()
	add_child(dlg)
	var region := RegionRunner.new()
	runner = dlg
	region.setup("red_reaches", self)
	var life := NpcLife.new()
	host.add_child(life)
	life.setup(host, "res://game/world/red_reaches/rr_npcs.json", "res://game/canon/npcs/red_reaches.json", region, dlg, func() -> Vector3: return Vector3.ZERO, func(_x: float, _z: float) -> float: return 0.0, func() -> String: return "day", "red_reaches")
	ok(life.ids().size() == 12, "12 canon npcs spawned (%d)" % life.ids().size())
	var reg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://game/art/models/npcs/npc_registry.json"))
	for id in life.ids():
		ok(reg["npcs"].has(id), "registry has %s" % id)
		ok(DialogueRunner.exists("rrn_%s_meet" % id), "dialogue meet exists for %s" % id)
	life.talk("oda_keth")
	ok(dlg.dialogue_id == "rrn_oda_keth_meet", "first talk plays meet (%s)" % dlg.dialogue_id)
	dlg.skip_all()
	GameState.set_flag("rr_act1_done", true)
	ok(life.quest_state("rr_well_line") == "open", "act 1 opens the Well Line quest")
	life.talk("oda_keth")
	ok(dlg.dialogue_id == "rrn_oda_keth_quest", "second talk offers the quest (%s)" % dlg.dialogue_id)
	life.handle_event("offer:rr_well_line")
	dlg.skip_all()
	ok(life.quest_state("rr_apprentice_arch") == "locked", "act-2 quest stays locked in act 1")
	var before := Ledger.count({"type": "chose"})
	life.handle_event("rec:oda_cup")
	ok(Ledger.count({"type": "chose"}) == before + 1, "rec: event records in the Ledger")
	region.apply_quest_choice("rr_well_line", "hand_crank")
	life.talk("oda_keth")
	ok(dlg.dialogue_id == "rrn_oda_keth_turnin", "finished quest plays turn-in (%s)" % dlg.dialogue_id)
	dlg.skip_all()
	life.talk("oda_keth")
	ok(dlg.dialogue_id in ["rrn_oda_keth_react", "rrn_oda_keth_repeat"], "then react/repeat (%s)" % dlg.dialogue_id)
	dlg.skip_all()
	host.queue_free()
	dlg.queue_free()

# ---------------------------------------------------------------- exploration layer (Red Reaches open-world feel)
func _test_explore() -> void:
	fresh()
	var d := RrExplore.load_data()
	ok(not d.is_empty(), "rr_explore.json loads")
	var floors := RrExplore.load_floors()
	ok(floors.size() >= 20, "layout floors load (%d)" % floors.size())
	var reg := RegionRunner.load_recipe("red_reaches")
	# data integrity: every authored point stands on a floor, ids are unique, species exist
	var ids: Dictionary = {}
	for p in d["places"]:
		ok(not ids.has(p["id"]), "unique place id %s" % p["id"])
		ids[p["id"]] = true
		ok(ExploreRules.on_floor(floors, float(p["pos"][0]), float(p["pos"][1]), -p.get("r", 10.0)), "place %s is near walkable ground" % p["id"])
		if p.has("waypoint"):
			ok(ExploreRules.on_floor(floors, float(p["waypoint"][0]), float(p["waypoint"][1]), 1.5), "waypoint of %s stands on a floor" % p["id"])
		if p.has("codex"):
			ok(codex_has(str(p["codex"])), "codex page %s exists" % p["codex"])
	var spoke_ids: Array = reg["spokes"].map(func(s): return s["id"])
	for sid in spoke_ids:
		ok(d["spoke_waypoints"].has(sid), "spoke %s has a waypoint" % sid)
	for sid in d["spoke_waypoints"]:
		var w: Array = d["spoke_waypoints"][sid]
		ok(ExploreRules.on_floor(floors, float(w[0]), float(w[1]), 1.5), "spoke waypoint %s on floor" % sid)
	var g: Array = d["gate_landing"]["pos"]
	ok(ExploreRules.on_floor(floors, float(g[0]), float(g[1]), 1.5), "gate landing on floor")
	for l in d["links"]:
		ok(ExploreRules.on_floor(floors, float(l["a"][0]), float(l["a"][1]), 1.0) and ExploreRules.on_floor(floors, float(l["b"][0]), float(l["b"][1]), 1.0), "link %s ends on floors" % l["id"])
		var span := Vector2(float(l["a"][0]) - float(l["b"][0]), float(l["a"][1]) - float(l["b"][1])).length()
		ok(span <= 20.0, "link %s hop is %.1f m (<= 20)" % [l["id"], span])
	var zone_ids: Dictionary = {}
	for z in d["roaming"]["zones"]:
		ok(not zone_ids.has(z["id"]), "unique zone %s" % z["id"])
		zone_ids[z["id"]] = true
		ok(ExploreRules.on_floor(floors, float(z["c"][0]), float(z["c"][1]), float(z["r"]) * 0.5), "zone %s core is on a floor" % z["id"])
		for gr in z["groups"]:
			ok(gr["species"] in ["skitter_mite", "dominion_drone", "plate_beetle"], "zone %s species %s is a roamer" % [z["id"], gr["species"]])
			ok(int(gr["n"]) <= int(d["roaming"]["global_cap"]), "group fits the cap")
		for s in d["roaming"]["safe"]:
			ok(Vector2(float(z["c"][0]) - float(s[0]), float(z["c"][1]) - float(s[1])).length() > float(s[2]) + float(z["r"]) * 0.5, "zone %s clear of safe area" % z["id"])
	# guide ladder: markers exist in layout
	var lay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://game/world/red_reaches/layout.json"))
	for gd in d["guide"]:
		ok(lay["markers"].has(gd["marker"]), "guide marker %s exists" % gd["marker"])
	# rules: steering
	var me := Vector3.ZERO
	var s1 := ExploreRules.steer(me, Vector3(1, 0, 0), [Vector3(0.6, 0, 0)], 1.35)
	ok(absf(s1.z) > 0.3 and s1.length() > 0.99, "steer sidesteps a body dead ahead (%s)" % s1)
	var s2 := ExploreRules.steer(me, Vector3(1, 0, 0), [Vector3(5, 0, 0)], 1.35)
	ok(s2.is_equal_approx(Vector3(1, 0, 0)), "steer ignores far bodies")
	var s3 := ExploreRules.steer(me, Vector3(1, 0, 0), [Vector3(0, 0, 0.5)], 1.35)
	ok(s3.z < 0.0, "steer pushes away from a body beside us")
	ok(ExploreRules.steer(me, Vector3(1, 0, 0), [me], 1.35).is_equal_approx(Vector3(1, 0, 0)), "steer ignores itself")
	# two NPCs walking head-on pass each other without ever overlapping closer than 0.5 m
	var a := Vector3(-4, 0, 0)
	var b := Vector3(4, 0, 0)
	var min_gap := 99.0
	for _i in 600:
		var da := ExploreRules.steer(a, (Vector3(4, 0, 0) - a).normalized(), [b], 1.35)
		var db := ExploreRules.steer(b, (Vector3(-4, 0, 0) - b).normalized(), [a], 1.35)
		a += da * 0.02
		b += db * 0.02
		min_gap = minf(min_gap, a.distance_to(b))
	ok(min_gap > 0.5 and a.x > 3.0 and b.x < -3.0, "head-on NPCs slip past each other (gap %.2f, a.x %.1f)" % [min_gap, a.x])
	ok(ExploreRules.free_indices([Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(5, 0, 0)], [Vector3(0.5, 0, 0)], 1.5) == [2], "free_indices drops reserved stations")
	# respawn rules
	ok(ExploreRules.cooldown(100.0, 0) == 100.0 and ExploreRules.cooldown(100.0, 1) == 160.0 and ExploreRules.cooldown(100.0, 20) == 400.0, "respawn cooldown grows then caps")
	var ents := [{"species": "a", "w": 3}, {"species": "b", "w": 1}]
	ok(ExploreRules.pick_weighted(ents, 0.0) == 0 and ExploreRules.pick_weighted(ents, 0.99) == 1, "weighted pick ends")
	ok(ExploreRules.pick_weighted(ents, 0.5, {"a": 0.0}) == 1, "phase mod can zero a species")
	ok(ExploreRules.pick_weighted(ents, 0.5, {"a": 0.0, "b": 0.0}) == -1, "all zero -> no pick")
	# map maths
	ok(ExploreRules.to_map(10, -5, 2.0) == Vector2(20, -10), "to_map scales")
	ok(ExploreRules.clamp_to_edge(Vector2(100, 50), 40.0) == Vector2(40, 20), "clamp_to_edge keeps the ray")
	ok(ExploreRules.compass_word(0, -10) == "N" and ExploreRules.compass_word(10, 0) == "E" and ExploreRules.compass_word(-10, 10) == "SW", "compass words")
	ok(ExploreRules.shape_poly(floors[0]).size() >= 12 and ExploreRules.shape_poly(floors[1]).size() >= 12, "floor polygons")
	ok(ExploreRules.on_floor(floors, 0, 0) and not ExploreRules.on_floor(floors, 0, 45), "on_floor query")
	# common loot regrows each descent, uncommon stays taken
	var extra: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://game/world/red_reaches/world_extra.json"))
	var common_i := -1
	var rare_i := -1
	var li := 0
	var rarity: Dictionary = {}
	for row in reg["loot_table"]:
		rarity[row["item"]] = row.get("rarity", "common")
	for lt in extra["loot"]:
		if rarity.get(lt["item"], "") == "common" and common_i < 0:
			common_i = li
		if rarity.get(lt["item"], "") != "common" and rare_i < 0:
			rare_i = li
		li += 1
	ok(common_i >= 0 and rare_i >= 0, "loot table has common and rarer drops")
	GameState.flags["_loot_%d" % common_i] = true
	GameState.flags["_loot_%d" % rare_i] = true
	var cleared := RrExplore.regrow_common_loot(extra, lay, reg["loot_table"])
	ok(cleared >= 1 and not GameState.flags.has("_loot_%d" % common_i) and bool(GameState.flags.get("_loot_%d" % rare_i, false)), "common loot regrows, rarer stays taken (%d)" % cleared)

func codex_has(id: String) -> bool:
	var cj: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://game/canon/codex.json"))
	return cj is Dictionary and (cj as Dictionary).get("entries", {}).has(id)

## Drives the real Red Reaches level headless: discovery, waypoints, fast-travel rules, climb links, roaming spawn / respawn rules.
func _test_explore_level() -> void:
	fresh()
	GameState.items = {}
	GameState.codex = []
	var lvl: Node3D = load("res://game/world/red_reaches/red_reaches.tscn").instantiate()
	add_child(lvl)
	for _i in 6:
		await get_tree().process_frame
	var ex: RrExplore = lvl.explore
	ok(ex != null and ex.hud != null, "level builds the exploration layer + HUD")
	if ex == null:
		lvl.queue_free()
		return
	ok(ex.pois.size() == 13, "13 places (7 + 6 spokes): %d" % ex.pois.size())
	lvl.runner.skip_all()
	lvl.party.input_enabled = true
	var lead: PlayableCritter = lvl.party.get_leader()
	# discovery
	lead.teleport(lvl.ground(Vector3(118, 0, -2), 0.3))
	ex._discover_tick(lead.global_position)
	ok(bool(GameState.flags.get("_poi_waystation_camp", false)) and "place_waystation" in GameState.codex, "walking into the Waystation discovers it and opens its codex page")
	ok(Ledger.count({"type": "discovered", "target": "waystation_camp"}) == 1, "discovery recorded in the Ledger")
	ex._discover_tick(lead.global_position)
	ok(Ledger.count({"type": "discovered", "target": "waystation_camp"}) == 1, "discovery fires once")
	var wps := ex.waypoints()
	var unl: Array = wps.filter(func(w): return w["unlocked"]).map(func(w): return w["id"])
	ok("gate_landing" in unl and "waystation_camp" in unl and not ("survey_camp" in unl), "waypoints: gate + found places only (%s)" % [unl])
	ok(ex.floors.any(func(f): return ex.floor_seen(f)), "walked ground is charted on the map")
	for _i in 6:
		await get_tree().process_frame
	var hx := int((118.0 - ExploreHud.MAP_X0) * ExploreHud.PX_M)
	var hy := int((-2.0 - ExploreHud.MAP_Z0) * ExploreHud.PX_M)
	ok(ex.hud._chart.get_pixel(hx, hy).r > 0.5, "charted Waystation floor is baked into the minimap texture")
	ok(ex.hud._chart.get_pixel(int((300.0 - ExploreHud.MAP_X0) * ExploreHud.PX_M), hy).r < 0.2, "unwalked ground stays blank")
	# fast-travel rules
	ok(ex.travel_reason("gate_landing") == "The way is blocked", "no fast travel back across the uncrossed Gap (%s)" % ex.travel_reason("gate_landing"))
	ok(ex.travel_reason("survey_camp") == "Not found yet", "undiscovered waypoint refused")
	GameState.set_flag("rope_dropped", true)
	ok(ex.travel_reason("gate_landing") == "", "fast travel allowed once the road is open (%s)" % ex.travel_reason("gate_landing"))
	var foe: EnemyBase = lvl.spawn_enemy("skitter_mite", lead.global_position + Vector3(6, 0, 0))
	foe.aggro = true
	ok(ex.travel_reason("gate_landing") == "Enemies nearby", "awake enemies block fast travel")
	foe.queue_free()
	await get_tree().process_frame
	lvl.field.enemies.erase(foe)
	ok(ex.travel("gate_landing") == "", "travel starts")
	await get_tree().create_timer(1.2).timeout
	ok(lead.global_position.x < 12.0 and lvl.party.input_enabled, "party arrived at the Gate and has control again (x=%.1f)" % lead.global_position.x)
	ok(ex.travel_reason("waystation_camp").begins_with("Catch your breath"), "travel has a cooldown")
	# climb links
	var inter := ex.interactables()
	ok(inter.size() == 4, "two climb links -> four interact points")
	var l0: Dictionary = ex.data["links"][0]
	ok(not ex._link_ok(l0, 0), "the cut to the Vault is closed until the boulder is broken (story barrier)")
	GameState.set_flag("boulder_broken", true)
	ok(ex._link_ok(l0, 0) and ex._link_ok(l0, 1), "...and open both ways after")
	var e := ex.link_ends(l0, 0)
	lead.teleport(lvl.ground(e[0], 0.3))
	lead.state = "normal"
	ex._do_link(l0, 0)
	await get_tree().create_timer(2.0).timeout
	var dest: Vector3 = e[1]
	ok(Vector2(lead.global_position.x - dest.x, lead.global_position.z - dest.z).length() < 1.5, "leader hops the cut (%s)" % lead.global_position)
	var partner: PlayableCritter = lvl.party.get_partner()
	ok(Vector2(partner.global_position.x - dest.x, partner.global_position.z - dest.z).length() < 4.0, "partner follows the hop")
	# roaming encounters
	GameState.set_flag("valley_clear", true)
	lead.teleport(lvl.ground(Vector3(104, 0, -1), 0.3))
	var z: Dictionary = ex._zones[0]
	ok(z["def"]["id"] == "valley_flats" and (z["live"] as Array).is_empty(), "valley zone starts empty")
	ex._roam_tick()
	ok(ex._spawn_queue.is_empty(), "nothing spawns before the zone's initial delay")
	z["next_ok"] = 0.0
	lead.teleport(lvl.ground(Vector3(56, 0, 0), 0.3))
	ex._roam_tick()
	ok(ex._spawn_queue.is_empty(), "nothing spawns within sight of the player")
	lead.teleport(lvl.ground(Vector3(104, 0, -1), 0.3))
	lvl.field.in_combat = false     # the valley's own mites are awake; roamers only join a quiet field
	ex._roam_tick()
	var queued := ex._spawn_queue.size()
	ok(queued >= 2 and queued <= 3, "a mite group is queued when the player is 48 m away (%d)" % queued)
	var t0 := Time.get_ticks_usec()
	ex._spawn_one()
	var one_ms := float(Time.get_ticks_usec() - t0) / 1000.0
	while not ex._spawn_queue.is_empty():
		ex._spawn_one()
	print("[TEST] info roamer spawn cost %.1f ms for the first mite" % one_ms)
	var live: Array = z["live"].duplicate()
	ok(live.size() == queued, "queued group spawned one per call")
	for m in live:
		ok(absf(lvl.height_at(m.global_position.x, m.global_position.z) + 4.0) < 2.0, "roamer stands on the valley floor")
	ex._roam_tick()
	ok(ex._spawn_queue.is_empty() and z["live"].size() == queued, "a populated zone does not stack groups")
	for m in live:
		m.removed.emit(m)
	ok(int(z["clears"]) == 1 and float(z["next_ok"]) >= ex.clock + 149.0, "group cleared -> 150 s cooldown")
	ex._roam_tick()
	ok(ex._spawn_queue.is_empty(), "zone rests during its cooldown")
	z["next_ok"] = 0.0
	lvl.field.in_combat = false
	ex._roam_tick()
	while not ex._spawn_queue.is_empty():
		ex._spawn_one()
	for m in z["live"].duplicate():
		m.removed.emit(m)
	ok(int(z["clears"]) == 2 and float(z["next_ok"]) >= ex.clock + 239.0, "second clear -> longer cooldown (x1.6)")
	ok(bool(z["retired"]), "zone retires after max_clears (no endless grind)")
	z["next_ok"] = 0.0
	lvl.field.in_combat = false
	ex._roam_tick()
	ok(ex._spawn_queue.is_empty(), "a retired zone never spawns again this descent")
	# the live cap
	var cap := int(ex.data["roaming"]["global_cap"])
	ok(ex.live_roamers() <= cap, "live roamers never exceed the cap")
	# busy states suppress spawning
	var z2: Dictionary = ex._zones[1]
	GameState.flags["_spoke_echo_hollow"] = true
	z2["next_ok"] = 0.0
	lead.teleport(lvl.ground(Vector3(104, 0, -1), 0.3))
	lvl.burden_active = true
	ex._roam_tick()
	ok(ex._spawn_queue.is_empty(), "no roamers during the Burden crossing")
	lvl.burden_active = false
	lvl.field.in_combat = false
	ex._roam_tick()
	ok(not ex._spawn_queue.is_empty(), "spoke guardians return once the Burden is over and the spoke is visited")
	ex._spawn_queue.clear()
	for _i in 12:
		await get_tree().process_frame
	lvl.queue_free()
	await get_tree().process_frame
	fresh()                          # leave no test flags behind for the quit-time autosave
	GameState.codex = []
	GameState.items = {}


func _test_hub_flow() -> void:
	var f := {}
	ok(HubFlow.objective_id(f) == "table" and HubFlow.primary_label(f) == "Meet Mara", "hub: new game objective is Mara")
	ok(not HubFlow.spot_visible("gate", f) and HubFlow.spot_visible("table", f), "hub: gate hidden before briefing")
	ok(HubFlow.places_list(f).is_empty(), "hub: no places list before briefing")
	ok(not HubFlow.show_gear_bonds(f), "hub: gear/bonds hidden at start")
	f["briefed"] = true
	ok(HubFlow.objective_id(f) == "gate" and HubFlow.primary_label(f) == "Descend" and HubFlow.primary_spot(f) == "gate", "hub: briefed -> Descend")
	ok(HubFlow.spot_visible("lab", f) and not HubFlow.spot_visible("ledger", f) and not HubFlow.spot_visible("habitat", f), "hub: secondary places unlock gradually")
	ok(not ("gate" in HubFlow.places_list(f)), "hub: objective not duplicated in Places")
	f["descents"] = 1
	ok(HubFlow.spot_visible("board", f) and HubFlow.show_gear_bonds(f), "hub: board/gear after first descent")
	f["rr_complete"] = true
	ok(HubFlow.objective_id(f) == "table" and HubFlow.primary_label(f) == "Debrief", "hub: debrief after descent")
	f["debriefed"] = true
	ok(HubFlow.objective_id(f) == "habitat" and HubFlow.spot_visible("habitat", f), "hub: habitat objective")
	f["habitat_built"] = true
	f["slice_complete"] = true
	ok(HubFlow.objective_id(f) == "" and HubFlow.primary_spot(f) == "gate" and HubFlow.primary_label(f) == "Descend", "hub: free roam falls back to Descend")
	var rc := HubFlow.recap_lines({"items": {"salvage": 1}, "specimens": 0, "codex": 3, "standing": 0}, {"items": {"salvage": 7, "reach_soil": 2}, "specimens": 1, "codex": 5, "standing": 2})
	ok(rc.size() == 4 and "+6 salvage" in rc[0] and "+2 reach_soil" in rc[0], "hub: recap gathered items diff")
	ok(HubFlow.recap_lines({"items": {}}, {"items": {}}).is_empty(), "hub: empty recap when nothing changed")

func _test_hud_flow() -> void:
	ok(HudFlow.shorten("short") == "short", "hud: short text untouched")
	var long := HudFlow.shorten("Combo unlocked: PROBABLE IMPACT — Gravity Pull during Premonition, then keep going")
	ok(long.length() <= HudFlow.TOAST_MAX_CHARS and long.ends_with("…"), "hud: long toast is cut with ellipsis")
	ok(HudFlow.shorten("Codex updated: Lichen") == "Codex: Lichen", "hud: codex prefix shortened")
	var q := HudFlow.ToastQueue.new()
	q.push("a", "info", 0.0)
	q.push("a", "info", 0.0)
	ok(q.queue.size() == 1, "hud: duplicate toast ignored")
	ok(q.tick(0.0) and q.current["text"] == "a", "hud: first toast shows")
	q.push("b", "info", 0.1)
	q.push("c", "warning", 0.1)
	q.push("d", "codex", 0.1)
	q.push("e", "info", 0.1)
	ok(q.queue.size() == HudFlow.ToastQueue.MAX_QUEUE and q.dropped == 1, "hud: backlog capped, lowest priority dropped")
	q.tick(0.5)
	ok(q.current["text"] == "a", "hud: no cut-in before MIN_SHOW")
	q.tick(1.0)
	ok(q.current["text"] == "c", "hud: warning cuts in after MIN_SHOW")
	var t := 1.0
	var seen: Array = []
	for i in 40:
		t += 0.5
		q.tick(t)
		if not q.current.is_empty() and (seen.is_empty() or seen[-1] != q.current["text"]):
			seen.append(q.current["text"])
	ok(q.current.is_empty() and q.queue.is_empty(), "hud: queue drains")
	ok(seen.size() == 3, "hud: backlog shows one at a time")
	var fl := {}
	ok(HudFlow.take_tip(fl, "scan") != "" and HudFlow.take_tip(fl, "scan") == "", "hud: tip shown once")
	ok(HudFlow.take_tip(fl, "nope") == "", "hud: unknown tip ignored")
	var r0 := HudFlow.reveal({}, INF, false, false)
	ok(not r0["combat"] and not r0["scan"], "hud: new player sees only core controls")
	ok(HudFlow.reveal({}, 10.0, false, false)["combat"], "hud: enemy near reveals abilities")
	ok(HudFlow.reveal({}, INF, true, false)["combat"], "hud: using an ability reveals them")
	ok(HudFlow.reveal({"_hud_combat": true}, INF, false, false)["combat"], "hud: reveal latches")
	ok(HudFlow.reveal({"valley_clear": true}, INF, false, false)["scan"], "hud: scan reveals when the valley asks for it")
	var vet := HudFlow.reveal({"rr_complete": true}, INF, false, false)
	ok(vet["combat"] and vet["scan"], "hud: veterans see everything")
