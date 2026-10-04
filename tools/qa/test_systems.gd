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
	await _test_npcs()
	print("[TEST] pass=%d fail=%d" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)

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
