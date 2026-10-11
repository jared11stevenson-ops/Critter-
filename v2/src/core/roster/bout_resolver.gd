class_name BoutResolver
extends RefCounted
## Applies a finished bout to a surviving critter (pure rules). Death is handled by RosterState.kill().
##  Sparring: no progression except a little Bond (+ small reward). Contest: counts, injuries, no death.
##  Blood Bout: counts, the finishing blow can kill (killed outcome is downgraded to a loss in lower tiers).

const NEAR_DEATH_BELOW := 0.10
const CONTEST_SCAR_BELOW := 0.15
const MAX_SCARS := 3
const SCAR_POOL := ["torn_wing", "cracked_shell", "chipped_horn", "bent_antenna", "split_mandible", "scarred_eye"]


## Effective outcome after the stakes rule: only Blood Bouts kill.
static func effective_outcome(o: BoutOutcome) -> String:
	if o.outcome == "killed" and not StakesTier.can_kill(o.stakes):
		return "loss"
	return o.outcome


static func _stress_delta(stakes: int, oc: String) -> float:
	if stakes == StakesTier.SPARRING:
		return -2.0
	var d := {"win": 4.0, "loss": 12.0, "yield": 15.0}.get(oc, 12.0) as float
	return d + (4.0 if stakes == StakesTier.BLOOD else 0.0)


## Mutates `c`; returns {outcome, reward, chapters, scar, bond_gained, near_death, rival_win}. Not for killed outcomes.
static func apply(c: CritterInstance, o: BoutOutcome, rules: StoryRules, economy: Economy) -> Dictionary:
	var oc := effective_outcome(o)
	var rep := {"outcome": oc, "reward": {}, "chapters": [], "scar": "", "bond_gained": 0, "near_death": false, "rival_win": false}
	c.vitality = clampf(o.final_vitality, 0.05, 1.0)   # a survivor never sits at exactly 0
	c.stress = clampf(c.stress + _stress_delta(o.stakes, oc), 0.0, 100.0)
	var reward := economy.reward_for(o.stakes, oc)
	economy.grant(reward)
	rep["reward"] = reward
	if o.stakes == StakesTier.SPARRING:
		c.bond_points += 1
		rep["bond_gained"] = 1
		rep["chapters"] = rules.evaluate(c)
		return rep
	c.bouts_survived += 1
	var bond := 3 + (1 if o.stakes == StakesTier.BLOOD else 0) + (1 if oc == "win" else 0)
	c.bond_points += bond
	rep["bond_gained"] = bond
	if o.moment != "":
		c.add_moment(o.moment, 70.0)
	if o.min_vitality < NEAR_DEATH_BELOW:
		c.near_death_count += 1
		rep["near_death"] = true
		c.add_moment("Survived with %d%% vitality left" % int(round(o.min_vitality * 100.0)), 100.0 - o.min_vitality * 100.0)
	if oc == "win":
		if rules.is_rival(c.species, o.opponent_species):
			c.wins_vs_rival += 1
			rep["rival_win"] = true
			c.add_moment("Beat its rival, the %s" % rules.species_title(o.opponent_species), 85.0)
		elif o.stakes == StakesTier.BLOOD:
			c.add_moment("Won a Blood Bout against a %s" % rules.species_title(o.opponent_species), 50.0)
	if o.stakes == StakesTier.CONTEST and (oc == "loss" or oc == "yield" or o.min_vitality < CONTEST_SCAR_BELOW):
		if c.scars.size() < MAX_SCARS:
			var id: String = SCAR_POOL[(c.bouts_survived + c.scars.size()) % SCAR_POOL.size()]
			c.scars.append({"id": id, "tier": o.stakes, "at_bout": c.bouts_survived})
			rep["scar"] = id
		else:
			c.stress = clampf(c.stress + 10.0, 0.0, 100.0)
	rep["chapters"] = rules.evaluate(c)
	return rep
