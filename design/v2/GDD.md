# CRITTER v2 — Game Design Document (Lead, 2026-10-11)

Status: draft for creator review. Supersedes AAA_PLAN.md amendments where they conflict. Lore is deliberately thin: the premise is a hook, the
*characters* carry the story. The old Master Lore Bible is archived as optional flavor; the creator will rewrite lore later.

## 1. Premise (the whole lore a player needs)
Beneath Earth's smallest scale lies **the Under**: a quantum realm eight times the size of Earth, ruled by giant-to-us insect-like peoples called **Critters**.
Humans (**Handlers**) descend through **Gates**, capture critters, **shrink them into Habitat Jars**, and bring them to Earth. On Earth, Handlers upgrade the
habitats and **battle** their critters in arenas and wild bouts. **When a critter dies, it is dead forever.**

## 2. Pillars
1. **Every fight is high stakes.** A critter you have kept alive for weeks can die in one bad read. Fights must feel like the last thing that matters.
2. **Love through survival.** Each critter has a hidden life story. Chapters unlock only by staying alive. The longer it lives, the more you know and care; death ends the story forever.
3. **Seven, each unique, each equal.** You manage up to seven critters at once. Every critter has its own weapon, abilities, rhythm and silhouette; none is "the best."
4. **Read, counter, punish.** Combat is a 1v1 mind game of tells, timing and stamina, not button-mashing and not stat-checking.
5. **Cute-grim.** Goofy, expressive characters in a grand, melancholic, dangerous world (Adventure Time and Rick and Morty faces, Naruto energy, Elden Ring scale and mood).

## 3. The core loop (say it in one sentence)
> **Capture it. Raise it. Fight with it. Keep it alive.**

```
DESCEND (hunt a wild critter) -> DUEL it -> SEAL it in a jar -> RETURN -> RAISE it in its habitat -> FIGHT bouts with it -> SURVIVE (learn its story) or LOSE IT (forever) -> repeat
```
- Time scales: a **bout** is 1-3 minutes; a **session** (10-20 min) is 2-4 bouts plus habitat care; **progression** is weeks of keeping critters alive.
- First-five-minutes target: tap New Game, and within 60 seconds be dueling a wild critter; within 5 minutes hold your first jar.

## 4. The roster system: "The Seven"
- The player owns up to **7 jar slots** (the Rack). Each jar holds one critter and a habitat. Jars are visible on the Rack screen as glowing dioramas.
- **Bouts are 1v1.** Before a bout you choose which critter fights (and in team bouts, the order of three). Others rest, heal, train.
- **Team Bout (3 of 7):** sequential 1v1s; a critter that wins keeps its remaining vitality (no free heal); a critter that is Broken may be yielded. Stakes apply to each.
- **Care matters:** a critter that fights while Hurt or Stressed (unmet habitat needs) is weaker. Resting and feeding takes real choices, not waiting timers.
- Over-investment risk: you must decide whom to risk. Fielding only your favorite is how it dies.

## 5. Combat: "Clash Combat" (inspired by For Honor's intensity and counters, but its own system)
Fixed-tick (60 Hz) deterministic simulation, data-driven move frames. Three bars per critter: **Vitality** (life), **Stamina**, **Poise** (stagger resistance).

### 5.1 The Triangle (readable on a phone, deep with timing)
| Action | Beats | Loses to | Notes |
|---|---|---|---|
| **Strike** (tap light / hold heavy) | Grab (faster startup) | Guard | Light = fast chain; Heavy = slow, large damage and guard-crush |
| **Guard** (hold) | Strike | Grab | **Perfect Guard** (parry): guard pressed in the 8 frames before impact negates damage, stuns attacker, opens a **Riposte** |
| **Grab** (button) | Guard | Strike | Throw: damage + positioning; **ring-out** on edges |
| **Dodge** (button + direction) | Heavy, Grab (6 i-frames) | spam (stamina) | Escapes; costs stamina; recovery punishes bad dodges |

- **Tells:** every move has a visible windup (the "tell"), longer for heavies. A skilled player reads the tell and picks the counter.
- **Mind games:** feints (cancel heavy windup into guard/grab), delayed strikes, bait-and-parry, stamina baiting.
- **Clash:** two strikes landing on the same tick bounce and open a one-beat mind game with a freeze frame.
- **Stamina:** strikes, dodges and guards spend it; empty = Winded (cannot guard well, slow). Stamina regenerates when not acting; pace is a skill.
- **Poise:** hits chip it; at zero the critter is Staggered (open to a free punish). Heavy critters have high Poise, light ones low.
- **Abilities:** each critter has **two unique abilities** (cooldown or resource) and **Last Stand**, a once-per-bout desperation move unlocked below 25% Vitality.
- **Environment:** arenas have edges, hazards and breakables. Ring-outs and hazard knockbacks are first-class kills in high stakes bouts.

### 5.2 The high-stakes moment: Yield or Last Stand
At low Vitality the player gets a clear choice before it is too late:
- **Yield:** the bout is lost, the critter lives, a penalty applies (reward lost, wound, Stress).
- **Fight on / Last Stand:** unlock the desperation move and risk everything.
This is the game's signature decision, repeated across hundreds of bouts.

### 5.3 Stakes tiers
| Tier | Death? | Rewards | Where |
|---|---|---|---|
| **Sparring** | No (practice, no progression except small bond) | Small | Habitat training ring |
| **Contest** | No death; **Injuries** (permanent scars that change a move) | Medium | League contests |
| **Blood Bout** | **Yes**, a finishing blow kills | Highest; rare critters; chapter unlocks | Wild encounters, black-market pits, the Gauntlet |
Default for wild captures is Blood Bout rules: you fight a wild critter to a Broken state and seal it (a killed critter cannot be captured).

### 5.4 Controls (touch first; prototype and choose by testing)
- Left thumb: move / lock-on strafe. Right thumb: **Strike** (tap/hold), **Guard** (hold), **Grab**, **Dodge**, plus two **Ability** buttons. Maximum 6 buttons.
- Alternative layout tested in M1: gestures (swipe = dodge, hold = guard).
- Gamepad layout from day one. Assist options (wider parry window, slow tells) available only in non-Blood tiers.
- All inputs buffered for 6 frames; input latency budget < 80 ms touch-to-pixel.

### 5.5 Balance is engineering, not guesswork
- **Power Budget:** each critter's kit is built from a point budget (damage, speed, reach, defense, mobility, utility); budgets are equal, shapes differ.
- **Bot tournament in CI:** every build runs every matchup (7x7 mirrored, 1000 simulated bouts each, with several AI skill profiles). Targets: overall win rate 45-55% per critter; no matchup worse than 40/60; the matchup matrix is published with each release.
- Rock-paper-scissors flavor between archetypes, never hard counters.

## 6. Capture and the Habitat Jar
1. **Hunt:** each region has wild critters you can read (their tells, habits, habitat).
2. **Duel:** beat it to Broken (not killed).
3. **Seal:** throw a **Scale Anchor jar** (timing mini-action); jar tier sets the success window; a sealed critter shrinks into the jar.
4. **Raise:** the jar is a diorama: soil, plants, light, humidity, food, toys, a training dummy. Upgrades improve Vitality growth, Stress resistance, recovery speed and critter happiness; some unlock **metamorphosis** (adult forms) later.
5. **Care loop:** feed, clean, play, train; neglect raises Stress, which weakens the critter in bouts.

## 7. Life Story system (the heart of "love")
- Every critter has a **Life Story** of 7 chapters. Chapter 1 unlocks when sealed. The rest unlock by **survival milestones**:
  | Chapter | Unlock (default; varies per critter) |
  |---|---|
  | 1 | Sealed in a jar |
  | 2 | Survive 3 bouts |
  | 3 | Survive 8 bouts and reach Bond 3 |
  | 4 | Survive a bout below 10% Vitality (a "near death") |
  | 5 | Survive 20 bouts |
  | 6 | Win a bout against its **Rival species** |
  | 7 (The Last Chapter) | Survive 40 bouts and complete **its personal trial** |
- **Bond** grows from time together: surviving bouts, feeding, habitat care, training. Higher Bond gives small, real benefits (not raw stats): tighter parry window, a unique voice line, a passive "trait."
- Each chapter is a short illustrated comic sequence (4-6 panels, written in the cute-grim tone) plus an in-habitat change (a memento appears in the jar).
- **Death:** a critter's story ends where it ended. The game writes an **Epitaph** from the chapters read and the critter's best moments, and adds it to the **Wall of the Fallen**. Locked chapters are visible as redacted panels so the player *knows what they lost.*
- **Legacy:** a fallen critter leaves a *relic* (craftable into a weapon charm) and its *last move* (a technique relatives can learn).

## 8. Progression and economy (kept simple)
- Currencies: **Scrap** (earned from bouts; buy jar upgrades), **Amber** (rare, from Blood Bouts; spend on tier-ups), **Reputation** (unlock arenas, jar tiers, wild regions).
- **No stat gear treadmill.** Upgrades improve *care and capacity*, and new *moves* are learned through bouts and Bond, not dropped.
- **Roster is the progression:** capturing new species, raising them, keeping them alive.

## 9. Worlds and arenas (minimal lore, maximal mood)
- **The Descent Zones** (wild regions): ruined colossal structures, golden fog, giant relics (an Elden Ring-scale mood): the Mirewalk, the Rust Span (a collapsing bridge arena), the Fungal Hollows, the Glasswing Dunes, the Nest-Cathedral.
- **The Arena** on Earth: a repurposed lab dome with tiers (Sparring Ring, Contest Hall, the Pit).
- Each region offers 3 wild species, its own hazards (edges, fungus, thorn pits) and a boss duelist.

## 10. Scope for 1.0 (tiered)
- **Tier 1 (launch core):** The Seven, Rack + jars + care loop, Clash Combat (full), 3 arenas, 3 regions, capture, Life Stories (7 critters x 7 chapters), stakes tiers, Wall of the Fallen, balance tooling.
- **Tier 2:** more species (target 14), breeding/metamorphosis, Team Bouts polish, boss duelists, leagues.
- **Tier 3:** online duels (deterministic sim allows input-synced PvP), seasonal events, more regions.
