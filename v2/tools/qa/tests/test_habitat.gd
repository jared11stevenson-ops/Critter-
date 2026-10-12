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
	return fails
