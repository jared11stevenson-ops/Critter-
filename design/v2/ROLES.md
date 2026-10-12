# CRITTER v2 — Roles: how a fighter wins (Lead, 2026-10-11)

**Creator brief:** every character has a role, but not tank/DPS/healer: new, inventive roles that give a real *motive* for choosing a fighter, without making favorites feel useless because a role counters them.
**Law check:** compatible with CREATOR_GDD (every Critter is its own fighting style; combat is ability-based; individual experience and career histories matter; expeditions require risking an existing Critter). Roles are a strategic layer on top of species identity.

## 1. Principle: a role is a WIN CONDITION, not a job in a party
Fights are 1v1, so roles don't split duties. A role answers: *how does this fighter take control of a fight, what does it need, and what is it good at outside the arena (expeditions, capture, habitat economy)?* Choosing a fighter is choosing a plan for the situation in front of you.

## 2. The seven roles (current cast)
| Role | Fighter | Wins by | Needs | Soft weakness | Expedition / capture / economy value |
|---|---|---|---|---|---|
| **Breaker** | Aruun | **Force**: shattering guard and poise; commit hard, punish whiffs | Rage, opening windows | Patient, evasive play drains Rage and Vitality | Clears obstacles, frees trapped critters; **risk: can kill a wild critter you wanted to capture** |
| **Reader** | Cigarra | **Information**: sees the next move early, bends the opponent's choices (mind control) | Future-Noise discipline | Unreadable or restricting opponents; overload under pressure | Scouts, reveals a wild critter's behavior and weak points, enables persuasion/observation outcomes |
| **Warden** | Bramvex | **Territory**: shapes the ground, funnels the enemy into traps, prepares | Time to set up, Intel built over the bout | Open, fast fights where there is nothing to hold | Secures extraction zones, makes hazardous regions survivable |
| **Brewer** | Scarlith | **Time**: damage and pressure that ripen the longer the fight goes | Patience, fungus patches | Short, sudden fights; being kited before cultures ripen | Converts expedition materials into bonus resources for habitats |
| **Anchor** | Mollusk | **Tempo debt**: delays and stores damage, controls when things land | Borrowed Seconds management | Burst that pays the debt all at once | The safest expedition pick: survives collapses and extraction under pressure |
| **Drifter** | Zephyr | **Initiative**: chooses when and where the fight happens; promises and loopholes | Low Poise, careful stamina | Traps and territory that catch mobility | Fast scouting, escapes, quick extraction; best at *getting out alive* |
| **Binder** | Nyxaris | **Restriction**: removes the opponent's options (freeze, cocoon, drag) | Silk reserve | Fast pressure that drains silk; high-Poise brutes | **Best at non-lethal capture** (subdue without killing) |
Future species receive a role on creation (or a blend of two). Roles are data on the species.

## 3. Soft counters, never hard counters
A 7-role pressure cycle gives every role exactly ONE mild advantage and ONE mild disadvantage; the other four matchups are neutral:
**Breaker > Warden > Drifter > Brewer > Anchor > Binder > Reader > Breaker.**
(Why each: Breakers smash set-ups and guards; Wardens trap mobile fighters; Drifters escape slow ripening and attrition; Brewers' time-pressure beats delay tricks; Anchors' inertia resists restriction; Binders' restriction denies foresight-based play; Readers punish committed, readable force.)
Rules that keep favorites viable:
1. **Magnitude cap:** an advantage is worth at most a 54/46 matchup in the bot tournament (tighter than the 40/60 global limit). The balance bot reports a role-pair matrix.
2. **Skill beats role:** every disadvantaged matchup has a clear, learnable counter-play (a specific tell, a safe move, an ability use) taught by Field Notes/UI hints; expert-level AI with the disadvantaged role must still win about 46+%.
3. **Seasoned (loyalty reward):** a critter that survives bouts against a role earns **Seasoned vs that role** (+ small defensive/reading bonus, for example a wider parry window, or +poise vs that role's signature move). The perk grows with experience and can fully offset the role disadvantage after about 10 bouts against that role. *The longer you keep your favorite alive, the less it fears its counter.* This also fits the permadeath/career design.
4. **Preview, not a draft:** before a bout you see the opponent's role and two key tells so you can choose, but there is no penalty for fielding a countered fighter.
5. **Comeback tools:** every Last Stand can swing a bad matchup (each is designed to answer its role's counter).

## 4. Why choosing matters (the strategic motive)
- **Tournament rule modifiers change which role shines** (each round announces a ruleset): *Sudden Death* (short fights, favors Breaker/Drifter), *Endurance* (long fights, favors Brewer/Anchor), *Hazard Arena* (terrain, favors Warden/Drifter), *Ring-out Rules* (favors Drifter/Binder/Breaker), *Gauntlet* (several opponents with carry-over Vitality, favors Anchor/Brewer), *Fog/Unknown Opponent* (favors Reader).
- **Expeditions need different roles:** capture without killing wants a Binder; a hazardous region wants an Anchor or Warden; an escape-heavy extraction wants a Drifter; clearing a blocked path wants a Breaker; a wary wild species wants a Reader. You risk one critter per expedition, so the right pick is a real decision.
- **Habitat economy:** Brewers boost resource yields; Wardens protect settlements during development; the role of a retired critter influences how its civilization builds (later milestone).
- **No role is strictly best:** every role has a clear job where it is the best choice and a clear job where it is the worst.

## 5. Implementation (staged)
1. **Now (data):** add `role` to each critter's data; the tournament bot reports a role-pair matrix with the ±54/46 target and a mirror/neutral baseline.
2. **UI:** role name and one-line "wins by / weak to" on character select and opponent preview.
3. **Rules modifiers:** ruleset flags in arenas/tournament config (Sudden Death, Endurance, Hazard, Ring-out, Gauntlet, Fog).
4. **Career (roster milestone):** Seasoned perks (bouts survived per opponent role), stored in the critter's history.
5. **Expedition milestone:** role-based expedition requirements and capture methods (Binder subdues, Breaker risks killing, etc.).

## 6. Rule: every new character must fit these roles (creator, 2026-10-11)
The seven roles above are the complete role set. **Any new character or species must be assigned to one of them** (or be explicitly designed as a blend of two, using the soft-counter cycle and the 54/46 cap). New roles are not added without a creator-approved design revision. Each new character's brief must state: role, how it wins, soft weakness, expedition/capture/economy value, and its place in the role-pair balance matrix.
