extends RefCounted
## Habitat Jars: peaceful, autonomous growth only from retired breeders, player allocates scrap, deterministic, saved.

func run() -> Array:
	var fails: Array = []
	var r := RosterState.new()
	var t := [1000]
	r.clock = func() -> int: return t[0]
	var a := r.seal("aruun", "Aruun")
	var h := r.habitat("aruun")
	QaCheck.eq(fails, h.founder_name, "Aruun", "the jar records its founding monarch")
	# no retired breeder: nothing is born, no matter how long
	t[0] += 600 * 30
	r.tick_habitats()
	QaCheck.eq(fails, h.descendants.size(), 0, "an active fighter alone does not start a family")
	QaCheck.is_true(fails, h.day == 30, "catch-up advanced 30 days")
	# retire -> family grows (deterministic)
	a.champion = true
	Career.retire(r, a.uid)
	for i in 40:
		h.step_day(r.retired_adults("aruun"))
	QaCheck.is_true(fails, h.descendants.size() > 0, "a retired critter starts a family")
	QaCheck.is_true(fails, h.descendants.size() + 1 <= h.capacity(), "population never exceeds capacity")
	var h2 := Habitat.new()
	h2.species = "aruun"
	h2.day = 30
	h2.last_real = 0
	h2.food = h.food
	# autonomous construction needs player-supplied materials
	QaCheck.eq(fails, h.structures.size(), 0, "no structure without materials")
	r.economy.scrap = 200
	QaCheck.eq(fails, h.supply(r.economy), "", "supplying materials works")
	QaCheck.eq(fails, h.supply(r.economy), "", "and again")
	QaCheck.eq(fails, h.feed(r.economy), "", "feeding works")
	for i in 20:
		h.step_day(r.retired_adults("aruun"))
	QaCheck.is_true(fails, h.structures.size() >= 1, "the critters built their first structure")
	QaCheck.is_true(fails, h.tribute > 0, "a living settlement earns tribute")
	var before := r.economy.scrap
	var got := h.collect(r.economy)
	QaCheck.is_true(fails, got > 0 and r.economy.scrap == before + got and h.tribute == 0, "collecting moves tribute into scrap")
	# poor player cannot allocate
	r.economy.scrap = 0
	QaCheck.is_true(fails, h.feed(r.economy) != "" and h.expand(r.economy) != "", "allocation costs scrap")
	# save round trip
	var r2 := RosterState.new()
	r2.load_dict(r.to_dict())
	var hb: Habitat = r2.habitat("aruun")
	QaCheck.is_true(fails, hb.day == h.day and hb.descendants.size() == h.descendants.size() and hb.structures.size() == h.structures.size(), "habitat survives save and load")
	# every species has a full ladder
	for sp in Career.data()["names"]:
		QaCheck.eq(fails, Habitat.ladder(sp).size(), 5, "%s has a 5-step ladder" % sp)
	# v2: roles, ages, lineage, links, founder death
	var h3 := Habitat.new()
	h3.species = "aruun"
	h3.founder_name = "Aruun"
	for i in 6:
		h3.descendants.append({"id": i, "name": "K%d" % i, "gen": 1, "born": 0, "role": "builder" if i < 3 else "forager"})
	h3.day = 100
	QaCheck.is_true(fails, h3.role_count("builder") == 3 and absf(h3.build_discount() - 0.15) < 0.001, "builders discount structures")
	QaCheck.eq(fails, h3.life_stage(h3.descendants[0]), "elder", "age 100 days is an elder")
	QaCheck.is_true(fails, h3.lineage_lines().size() == 2, "lineage lists the monarch and the generation")
	var r3 := RosterState.new()
	var ar := r3.seal("aruun", "Aruun")
	r3.seal("zephyr", "Whisk")
	r3.economy.scrap = 500
	QaCheck.eq(fails, r3.link_jars("aruun", "zephyr"), "", "two jars can be linked")
	QaCheck.is_true(fails, r3.habitat("zephyr").links.has("aruun") and r3.habitat("aruun").links.has("zephyr"), "links are two-way")
	QaCheck.is_true(fails, r3.link_jars("aruun", "zephyr") != "", "no double link")
	r3.kill(ar.uid, "test")
	QaCheck.is_true(fails, r3.habitat("aruun").monarch_fallen, "the founder's death is recorded in the jar")
	var r4 := RosterState.new()
	r4.load_dict(r3.to_dict())
	QaCheck.is_true(fails, r4.habitat("aruun").monarch_fallen and r4.habitat("aruun").links.has("zephyr"), "v2 fields survive save/load")
	# the shared Jar: districts, build_step, free passages between neighbours
	var rj := RosterState.new()
	var ca := rj.seal("aruun", "A1")
	ca.retired = true
	var cc := rj.seal("cigarra", "C1")
	cc.retired = true
	rj.seal("mollusk", "M1")
	var claimed := rj.unify_town()
	if claimed.size() != 3:
		fails.append("town: 3 claimed districts expected, got %d" % claimed.size())
	if not rj.habitat("aruun").links.has("cigarra") or not rj.habitat("cigarra").links.has("aruun"):
		fails.append("town: aruun and cigarra are neighbours and must be linked")
	if rj.habitat("mollusk").links.size() != 0:
		fails.append("town: mollusk has no claimed neighbour (zephyr/scarlith unclaimed)")
	var ha := rj.habitat("aruun")
	ha.materials = 0
	if ha.can_build(rj.retired_adults("aruun")) or ha.build_step(rj.retired_adults("aruun")) != "":
		fails.append("town: cannot build without materials")
	ha.materials = 40
	if not ha.can_build(rj.retired_adults("aruun")):
		fails.append("town: one retired adult and 40 materials must allow the first structure")
	if ha.build_step(rj.retired_adults("aruun")) != "Rope span" or ha.structures.size() != 1:
		fails.append("town: build_step must raise the Rope span")
	return fails
