# CRITTER — The Ground-Up Plan (Lead, 2026-10-11)

Status: **PROPOSAL for the creator's approval. No production starts until this is approved.**
Restore point: branch `archive/v0.15.0-before-restart` (everything built so far, untouched). Nothing is deleted.

How to read this: Part A is the diagnosis, B is the vision and pillars, C is the evolved gameplay loop (the heart of the plan),
D is the world and cast, E is how it should look, F is the technical foundation, G is how we work, H is the roadmap with gates,
I is scope tiers, J is risks, K is what I need from you.

---------------------------------------------------------------------------------------------------------------------

## A. Honest diagnosis: why the current build does not feel like a game yet

What exists is real: ~27,500 lines of GDScript, a Ledger/Rivals/Bonds/Promises engine, 310 automated tests, data validators, a QA
harness that plays the game by scripted touch, a perf reporter, and a playable Red Reaches slice. The trouble is not effort. It is the order we did things in.

1. **We built breadth before feel.** Twenty-five systems were designed and several wired in before one thing, moving and hitting, felt good
   on a phone. A player forgives thin content; they do not forgive a game that is unclear and hitchy in the first minute.
2. **The loop was never written down as one sentence a player can say.** The lore has a great loop (Book XXXII). The build exposed every
   system at once (HUD with 6 buttons, 8 hub labels, stacked toasts). Result: "the gameplay loop is very confusing."
3. **Art was gated on a model pipeline that could not reach the quality bar.** Scripted modeling plateaued around 65-70% of the sheets.
   Everything downstream (look, readability, "unappealing") inherits that. You are now outsourcing models, which is the right call; the
   game must be ready to receive them.
4. **Parallel agents edited overlapping files.** UI, hub, look and combat were touched by different passes with no shared contract, which is how a "last
   pass ruined a lot" happens. There was no automated "does it still feel/look/run the same" gate.
5. **Measurement lived on the wrong machine.** We tuned against a software renderer and phone screenshots sent by hand. Delivery was capped at 30 MiB
   by chat attachments, which pushed us to strip content rather than fix the pipeline.
6. **Monolithic scene scripts.** Level and hub logic grew into very large files (the world folder is ~9,700 lines). Changing one thing risks another.

None of this is fatal and none of it is a reason to say a goal cannot be reached. It tells us what to change: **prove feel first, write the loop first,
build to a spec the outsourced art can drop into, give every subsystem one owner, and gate every merge on measured results.**

---------------------------------------------------------------------------------------------------------------------

## B. Vision and pillars (from the Master Lore Bible v12)

**One-line pitch.** *You are a Handler. You shrink through a Gate into a world eight times the size of Earth, learn what you are looking at before you act on it,
and everything you do leaves something behind that you must live with when you come home.*

**The five pillars.** Every feature must serve at least one; features that serve none are cut.

| # | Pillar | Lore source | What the player feels | What it forbids |
|---|---|---|---|---|
| 1 | **Understand before you act** | Bk XXXII "Understanding context is a gameplay resource" | Curiosity, the Monster Hunter / Arceus pleasure of reading a creature | Treating every creature as a target |
| 2 | **Actions accumulate** | "Critter does not end. It accumulates." | Weight and ownership of consequences | Resettable, forgettable missions |
| 3 | **Bodies make cultures and powers** | Bk II §8, Bk III §11-12 | Every region and character plays differently for a *reason* | Reskinned regions, colored spell buttons |
| 4 | **Relationships are the progression** | Bk XXXII "Character progression" | Earning trust, unlocking combined techniques | A gear/numbers treadmill |
| 5 | **The Terrarium remembers** | Bk XII §55 | Pride; the base is a physical autobiography | A decorative housing minigame |

**Tone.** Wonder first, then moral weight. Humor is warm and dry (Mara, Scarlith, Zephyr). Humans are neither villains nor heroes (Humanity Rule).

**Benchmarks (what each teaches us, not what we copy).**
- *Genshin Impact / Wuthering Waves*: proof that a touch-first open-world action RPG can ship at high quality on phones; their control and camera model is our baseline.
- *Zelda: Breath of the Wild*: systemic interactions (physics + elements), reading the world instead of waypoints.
- *Monster Hunter*: learning an animal's behavior is the fun; ecology and habitats.
- *Pikmin*: small-scale, ecological, charming; a strong visual cousin for "you are tiny in a huge world."
- *Pokemon Legends: Arceus*: observation-based research as a loop.
- *Baldur's Gate 3*: persistent consequence and companions that react.
- *Elden Ring*: atmosphere, landmarks, discovery without hand-holding, restrained UI.
All are design references only: no names, art, text or code are reused.

**What "AAA" means for us, stated plainly.** A large studio has hundreds of people, so we will not match its content *volume* at launch. We can match its
*quality bar per minute of play* by (a) proving a flawless vertical slice, (b) building the content machine (data, tools, validators) before mass production, and
(c) scaling by tiers (Part I). "Triple-A" here is a measurable bar: feel, clarity, art direction, performance and polish gates that the slice passes before we scale.

---------------------------------------------------------------------------------------------------------------------

## C. The evolved gameplay loop

### C1. The loop in one sentence (the one players should be able to say)

> **Descend into a region, work out what is going on, choose how to step in, come home, and build something that remembers it.**

The lore's formula is `DESCEND -> EXPLORE -> UNDERSTAND -> INTERVENE -> RETURN -> BUILD -> LIVE WITH CONSEQUENCES -> DESCEND AGAIN`.
We keep it and make it legible by giving each beat a *screen*, a *verb*, a *decision* and a *reward*.

| Beat | Screen / place | Core verb | The decision | What you get |
|---|---|---|---|---|
| **Prepare** | Terrarium One (the Common) | Choose descent | Where, with whom, with what permits/tools | A *Descent Card*: goal, risks, who is coming |
| **Descend** | Gate | Cross; the Tilt | (cinematic beat; also a load mask) | Region state shown honestly |
| **Explore** | Region (open, non-linear) | Move, climb, glide, observe | Which lead to follow | Discoveries, landmarks, codex pages |
| **Understand** | Anywhere, via Field Notes | Observe, scan, ask, test | What *is* this? (wildlife / livestock / person / sacred / valuable / keystone) | Unlocks the *right* interventions |
| **Intervene** | World | Fight, contain, negotiate, build, rescue, trade, sneak, leave | How do I step in, or do I not | Outcome plus a *Legacy* written to the Ledger |
| **Return** | Gate, Terrarium | Debrief | What do I keep, who do I bring back | Recap: "what you brought back / what changed / what's next" |
| **Build** | Terrarium One | Habitat, embassy, labs, shops | What does my home need? | Capability: new bonds, tools, abilities, access |
| **Live with it** | Region on next descent | See the changed world | (the payoff) | Region state, rival and ally reactions |

### C2. Four nested time-scales (design every system against these)

| Scale | Length | The question we ask | Example |
|---|---|---|---|
| **Moment** | 0-5 s | Does it feel good to *do* this? | Dash, strike, grab, leap a gap |
| **Encounter** | 1-3 min | Is there a meaningful read-and-choose? | A swarm on a bridge approach |
| **Descent** | 15-25 min | Does it have a shape: curiosity, tension, payoff, a way home? | One expedition into the Fracture Valley |
| **Session / Arc** | 30-60 min / weeks | Do I want to come back and see what changed? | Bond questline, Terrarium growth, Era crisis |

A mobile session is usually 10-20 minutes, so a Descent must be *pausable and resumable at any moment* (safe-point saves) and offer a **Micro-Descent** (5-10 min)
for short sessions (adopted from the master plan, system 6).

### C3. Moment-to-moment: control and camera (mobile first)

- **Baseline: Genshin-class touch scheme.** Left thumb: movement stick. Right thumb: drag to orbit the camera; fixed arc of buttons: Attack, Knack 1, Knack 2,
  Dash/Dodge, Interact/Context. Swap partner and Field Notes sit on a secondary arc. *Maximum five always-visible action buttons.*
- **Camera:** third-person follow with free orbit and lock-on assist; presets for close/hero/wide stay as accessibility options. Combat framing widens automatically.
- **Auto-assists on by default** (aim, lunge, ledge), tunable in settings, because phone precision is limited. Input buffering (0.28 s) stays.
- **Controller and tablet layouts** are first-class from the start (left-handed mirroring already exists).
- **Frame target:** 60 fps on flagship at Medium, 30 fps on mid-range at Low; input latency and frame pacing are tracked as gameplay metrics, not as polish.

### C4. Exploration: open, non-linear, readable

- **Landmark-first design:** every region has 4-6 silhouettes visible from far away (the Red Span, a spire, a Thoughtstone vein). The player picks a landmark to head to; there is no mandatory path.
- **Layered discovery:** (1) see it, (2) hear/smell it (audio, particles), (3) a hint when near (the `secret` hints already built), (4) a reveal on the map. The map fills by *walking* (already built).
- **Traversal is a verb, and it differs by region** (Part D): spans and leaps (Red Reaches), vertical glide/climb (Canopy Fold), light-dependent paths (Lumen Depths), etc. Traversal is how the region teaches its identity.
- **Guidance without a quest marker wall:** a *soft* next-lead hint (the guide arrow built last pass) plus the codex; the player may ignore it.
- **Fast travel:** unlocked waypoints (built), refused during danger (built).
- **Rule:** a first-time player should be able to name their current goal at any moment (the "NEXT" objective) and see one clear way to progress.

### C5. Understand: the signature mechanic (this is what makes CRITTER not-another-action-RPG)

*Field Notes* turns observation into play. Looking at a creature, person or site reveals up to four **Reads**:

1. **Body**: what is it? (anatomy, Knack mechanism and cost; "its shell vibrates before it charges")
2. **Behavior**: what is it doing and why? (grazing, guarding, fleeing, nesting; watch for a few seconds, or test a response)
3. **Context**: what is it part of? (herd, habitat chain, trade route, shrine, a Dominion convoy's cargo)
4. **Value**: what is it to others? (food, livestock, sacred, extractable, keystone, person)

Reads fill in by *time and attention* (watching), *experiments* (throw bait, play a sound, block a path), *knowledge* (codex, NPC testimony, Old Road markers) and *bonds*
(each companion reads the world differently: Cigarra reads probabilities, Nerit reads light and absence, Mollusk reads structural load).
When enough Reads are known, the player may **commit an Interpretation** (e.g. "livestock under a herder's care"). A correct interpretation opens the right options
and shows a small, honest reward. A wrong one is *recoverable but has consequences* (a herder's trust drops; a keystone species is disturbed). There is no fail-state, only different futures.
This honors Bk XXXII ("Understanding context is a gameplay resource") and Pillar 1.

### C6. Intervene: eight verbs, never all at once

Each encounter offers the verbs that make sense for what was understood. Not every encounter has every verb.

| Verb | Fantasy | Mechanics (sketch) | Writes to Ledger |
|---|---|---|---|
| **Fight** | Force, when it is justified | Real-time action combat (C7) | kills, harm to ecology/people |
| **Contain** | Temporary Wild Containment of dangerous non-sapient wildlife | Weaken, then Scale Anchor; only valid on *wildlife* | species removed from region, specimen gained |
| **Negotiate / Contract** | Bond with a sapient | Dialogue + Promise wording + trust (built) | bond state, Promises |
| **Build** | Spanwright craft | Place/repair spans, ramps, shelters within a budget | infrastructure that persists |
| **Rescue** | Protective Extraction | Time-pressured save (Mollusk's "Borrowed Seconds") | lives saved, dependency created |
| **Trade** | Value without ownership | Barter, deliver, broker | route/price changes |
| **Sneak / Avoid** | Non-interference | Stealth, distraction, terrain (Bramvex's camouflage) | nothing disturbed (also recorded) |
| **Leave** | Deliberate non-interference | Walk away | recorded as a choice, can matter later |

**Capture-as-choice is the legal and moral spine of the bond/collect fantasy** (Bk IV §17, Bk XII §52): you may *Contain* dangerous wildlife, *Contract* with sapients,
*Rescue* the wounded, and be tempted by *Criminal Extraction* from the Undermarket. The creator's direction that sapient bonds are the main acquisition fits: **bonds are earned through staged, character-specific trust quests, never captured**.

### C7. Combat (real-time action, squad of three, readable, costly)

- **Structure:** real-time third-person action; 1 controlled character + 2 AI/swap partners (squad of three, tag-swap with cooldown; "squad size 2 vs 3" is a creator decision, default 3).
- **Read-and-counter:** enemy telegraphs get clearer as the hit approaches (built); a perfect dodge gives a window (built); Cigarra's Premonition can show ghosted outcomes.
- **Knack Wheel:** interactions are by *mechanism* (pressure vs silk, light reveals camouflage, cold slows fermentation) and shown in a simple in-combat hint, not a hidden table.
- **Ecological cost is the resource system, in-fiction and unique per character:**
  Aruun: Rage = self-damage margin; Cigarra: Future-Noise overload; Mollusk: Borrowed Seconds debt; Nerit: light budget; Nyxaris: mineral reserves; Solmara: celestial conditions; etc.
  This gives each character a distinct *rhythm*, not just different damage numbers (Pillar 3).
- **Team-ups and fusion** are unlocked by relationship state (a pair that trusts each other gets a combined technique; a pair in conflict refuses or alters it).
- **Combat is one answer among eight**, so it must be excellent but not the only gameplay.
- **Boss and Rival design:** bosses teach a mechanism; Ledger Rivals remember how you fight (built core). Patent note on the Nemesis system stays: IP attorney review before launch.

### C8. Return and Build: the Terrarium as the long game

- **Return beat:** a recap screen ("what you brought back / what changed / what's next") on every return (built last pass).
- **Habitat chains:** specimens need soil, microbes, humidity, light, food web (Bk I §5, III §13); a captured species needs a plant, which needs a fungus, which needs a decomposer.
  The most valuable Habitats are *ecosystems*, not menageries.
- **Three uses of every good creature** (Bk XII §53): Battle, Labor, Ecology.
- **Embassy Halls:** each bonded culture grows a wing of Terrarium One; it also unlocks tools, shops, quests and visitors.
- **The base remembers:** physical artifacts of your history (the bridge Aruun designed, a dark garden of Nerit's design, a damaged wall) are placed by *what happened*, not by a build menu alone.
- **Residents have species-shaped needs** (vibration, privacy, warmth, light cycles). Neglect has an in-field cost.
- **Expeditions:** bonded characters not in the squad can run offline missions (return rewards + Ledger entries) so that a short session still advances the world.

### C9. Persistent consequence: how it actually works

- **The Ledger** (built) is the single memory: events with tags (who, where, what, intent, outcome). Everything else reads it: dialogue reactions, rivals, bonds, region state, Terrarium.
- **Region State** is a small simulation (not a physics sim): each region has *Pressures* (Flood, Fire, War, Migration, Overgrowth, Disease, Extraction, Predator imbalance, Political control; Bk II §54) and *Populations* of key species.
  Rules update the state between descents using Ledger entries; the player sees *named* changes ("grazers have moved north since the beetles were thinned").
- **Design law:** one change must produce at least one *visible* result in the next descent and at least one *voice* (an NPC or companion comment) within two descents.
- **Eras:** a season (≈ 3-6 hours of play) frames a Crisis and leaves permanent Legacies (no "borrowed power"). Era 1 = *First Contact: Terrarium One* (Part D).
- **Factions without morality meters:** Stewardship Coalition vs Human Dominion are *pressures that offer opportunities*, never alignment bars. Dexter Mane is the parallel protagonist.

### C10. The first five minutes (what the new player does; every screen must serve this)

| Time | Where | The player does | The game teaches | Hidden metric |
|---|---|---|---|---|
| 0:00 | Title | Tap New Game | nothing; fast | time to input < 5 s |
| 0:20 | Terrarium One arrival (short, skippable) | Walk toward Mara | movement, camera orbit | no text wall |
| 1:00 | Mara briefs (comms-style, 3 lines) | Choose a descent card | the loop sentence | 1 button only |
| 2:00 | Gate Tilt, Red Reaches arrival | Walk to the first landmark | traversal, objective arrow | player moves within 5 s |
| 3:00 | First creature | Hold Field Notes: watch it | Reads, Interpretation | first Read in < 20 s |
| 4:00 | Choose to fight / leave / contain | Make the first intervention | a Ledger line appears | clear feedback |
| 5:00 | A glimpse of Aruun | A moment of character, not a lecture | the bond hook | emotional beat |

Success metric: **a stranger can describe the loop after five minutes without help**; we test this with real people (Part G).

---------------------------------------------------------------------------------------------------------------------

## D. The world and the cast, built from the bible

### D1. Scale and structure (Geography Rule: distance matters)

- The world is ~8x Earth and unmapped; we ship it as **regions** reached through a **Gate Map** that is a mosaic with blank spaces (already built as a stub).
- A region is *open and non-linear* inside, and *separated* from others. Regions never casually connect (Geography Rule); travel between homelands happens through Gates and Earth ("Gate compression").
- **Region Recipe** (data-driven, one file per homeland): ground, props, sky, creatures, music, encounters, state rules, traversal verb, settlements, mysteries.
- **Rule: a new region ships only with these seven things** (the "Region Bar"):
  1. a **traversal verb** that makes it feel physically different; 2. a **signature ecology** (≈ 10-14 species with Body/Behavior/Context/Value);
  3. a **palette and silhouette language** tied to its culture; 4. **3 settlements** with distinct institutions shaped by bodies (Bk II §8);
  5. one **bond questline** built on a character's core contradiction; 6. one **long mystery thread**; 7. a **set-piece** (siege, bridge, flood, ceremony).

### D2. Regions and the design hook each one carries (hooks are proposals grounded in the bible; creator may revise)

| Region | Character | Lore facts we build on | Proposed traversal / mechanic hook |
|---|---|---|---|
| **Terrarium One / The Common** | the hub, everyone | Lab that became a city; market; translation boards; Gate compression | Social hub: shops, bonds, base growth, Descent Cards |
| **Red Reaches** | Aruun | Plateaus, fracture valleys, Spanwrights, "carried weight," Thoughtstone, Morrow, Red Span | **Spans and burden:** leap/repair/build bridges; carry-weight puzzles; physics of load |
| **Canopy Fold** | Cigarra | Vertical continental ecology; settlements at different heights; probability routes | **Verticality:** climb/glide between canopy layers; "route by probability of safe passage" |
| **Lumen Depths** | Nerit | Light/dark, bioluminescence, "right to darkness" | **Light as terrain:** visibility, camouflage, places cameras cannot record |
| **Rainward** | Mollusk | Journeys, carved shells, temporal inertia, rescue doctrine | **Weather and delay:** rain-timed routes; rescue under collapse |
| **Briarwild** | Zephyr | Wind, pollination, spoken promises | **Wind and promises:** gliding, delivery chains, Promise Network |
| **Frostbloom** | Nyxaris | Silk-patterns as writing, cold, minerals cost | **Silk architecture:** build with and read patterns |
| **Velvet Warrens** | Scarlith | Fermentation, underground, waste into value | **Cultivation economy:** trade and fermentation chains underground |
| **Pelagic Expanse** | Solmara | Tide/gravity/celestial states; the Moon question | **Tides and gravity:** timing, diving, celestial states |
| **Thornmarch** | Bramvex | Camouflage, tactical terrain, extraction over victory | **Stealth and terrain tactics** |
| **Ember Expanse** | Solthrin (Second Contact) | Astral Roads; luminous lines across empty air | **Astral Roads:** temporary paths; later era |
| **Pharilux's lighthouse (Earth)** | Pharilux | 1897 anomaly; sealed foundation cavity ("closed is still working") | An Earth-side mystery location, no solution forced (Mystery Rule) |

### D3. Era 1 for the 1.0 launch: "First Contact" (proposed scope)

- **Terrarium One** (full hub, growing), **Red Reaches** (flagship region, deepest), plus **2 more homelands** chosen for contrast (proposal: **Canopy Fold** for verticality and **Lumen Depths** for light/dark).
- **Bonds:** Aruun and Cigarra fully authored (questline, team-ups, rivals), Nerit and one other (Mollusk or Zephyr) as full bonds; the rest of the First Ten present in the Common with smaller arcs (stories can end; the setting does not).
- **Antagonist:** Dexter Mane / Human Dominion pressure, Mara Venn / Stewardship as the counter-argument, never a single boss.
- **Long mysteries seeded:** Thoughtstone, the Boneyard markers, Pharilux 1897, Astral Roads, the Eightfold Paradox, Cigarra's blind spots (Bk XXXII "Long mysteries"). None need to resolve.
- Post-launch eras add homelands and cast (Part I).

### D4. The First Ten and the bond structure

A **Bond** is a staged, authored trust relationship, not a capture. Template (applied per character, using the contradiction in the bible):

1. **Meet** (the bible's contact rule: most of the First Ten meet on Earth, in the Common).
2. **Understand** (Field Notes on their culture, body and Knack; you learn what they do and what it costs them).
3. **Prove** (a descent into *their* homeland where the player acts according to what was understood; Promises matter).
4. **Contract** (the Promise wording is a game object; letter vs spirit).
5. **Grow** (relationship tiers unlock team-ups, camp scenes, Terrarium contributions).
6. **Strain** (a contradiction event the player must navigate: e.g. Aruun's urge to carry everything).

| Character | Contradiction (bible) | Distinct combat rhythm (proposal) | Distinct Terrarium contribution |
|---|---|---|---|
| Aruun | Famous for destruction, wants to build | Heavy, committed hits; Rage trades safety for power; Morrow thrown and recalled | Burden Architecture: spans and distributed-failure structures |
| Cigarra | Glimpses futures, cannot trust certainty | Premonition ghosts, counters, Future-Noise overload | Probability inspection of habitats and plans |
| Nerit | Creates visibility, values darkness | Light relocation, controlled absence | Lighting and privacy zones in Habitats |
| Mollusk | Delays consequences, cannot stop them | Time-delay setups, Borrowed Seconds debt | Rescue doctrine, structural testing |
| Zephyr | Treats rules as games, promises as sacred | Fast mobility, wind control | Promise Network (messages, deliveries) |
| Nyxaris | Beauty built to say something | Silk and venom control | Cold Archive, cultural-property rules |
| Pharilux | Guides, refuses to explain | Pressure, light, spectral tide | Thresholds (mystery) |
| Scarlith | Everything has value, so what is owned? | Decay and cultivation | Waste-to-value trade chains |
| Solmara | Understands celestial systems, puzzled by one moon | Tide/gravity states by environment | Habitat cycles and tides |
| Bramvex | Distrusts anyone, plans for extraction | Terrain, camouflage | Quarantine/detention law reform |

Presentation law: **approved sheets are binding.** Outsourced models must match them. We never redesign.

---------------------------------------------------------------------------------------------------------------------

## E. Art direction and the outsourced-model pipeline

### E1. Visual target

- **Stylized, painterly, illustrated:** the references are comic/concept-art sheets (clear inked silhouettes, warm gold-hour light with cool shade, saturated accents). The game matches that language: *toon-lit PBR-lite*, ink outline, rim light, color-script per region.
- **Contrast rule:** characters are always the highest-contrast, most saturated element; ground is calmer. Gold key light, teal fill; haze for depth. (Last pass's color script stays as a starting point but is re-tuned; its first version was too washed out.)
- **Region palettes must differ from one another and from the characters** (user note: characters must "pop").
- **Scale feel:** the player is tiny. Camera, props and fog make landscapes feel huge (a pebble is a boulder).

### E2. Who makes what

| Asset | Owner | Notes |
|---|---|---|
| Hero characters (First Ten + key NPCs) | **Outsourced (creator)** | Must follow the Model Spec below; placeholders until delivered |
| Creatures (wildlife) | Outsourced where hero-grade; otherwise procedural/kit | Ten to fourteen per region |
| Environment kits, terrain, props | In-house technical art using licensed/CC0 sources and procedural tools | Poly Haven, ambientCG, Quaternius, Kenney; all recorded in `design/ASSET_LICENSES.md` |
| VFX, shaders, UI | In-house | Procedural icons; GPU particles; budgets enforced |
| Audio | Creator tracks (slots reserved), CC0/licensed SFX | Music slots already exist |

### E3. The Model Spec (hand this to whoever builds the models)

To avoid another round of "it does not match," we publish a spec and an *automatic checker* the Lead runs on every delivery:

- **Format:** glTF 2.0 binary (`.glb`), one file per character, meters, Y-up, forward -Z, origin between feet.
- **Budgets:** hero character 25-40k triangles (LOD1 ≈ 12k, LOD2 ≈ 5k); NPC 8-15k; creature 3-12k; max 4 materials per hero; textures 2048² (hero), 1024² (NPC), ETC2/ASTC friendly.
- **Rig:** humanoid-compatible or documented custom skeleton; ≤ 75 bones; named sockets (`hand_R`, `hand_L`, `head`, `weapon`, `back`, `root`), facial blendshapes for 6 expressions (calm, happy, angry, sad, surprised, focused) where the character has a face.
- **Animations (hero set):** idle, walk, run, dash, 3-hit combo, 2 Knack casts, hit, stagger, down, get-up, interact, emote x2, plus per-character signature loops; root motion optional; each in-place + named by convention.
- **Materials:** base color, normal, ORM (occlusion/roughness/metal), emissive; no baked lighting; palette matches the approved sheet.
- **Fidelity gate (replaces our old 95/100 scorecard with a faster one):** side-by-side with the approved sheet at the locked cameras; silhouette IoU ≥ 0.85 at front/side/back and a landmark checklist signed by the creator. *The creator's eye is final.*
- **Delivery:** drop into `game/art/models/<id>/`; the **Import Doctor** (to be built, M0) validates names, scale, budget, bones and produces a one-page report.
- **Until delivery:** current models stay as placeholders; code never depends on model internals.

### E4. World art strategy

- **Kit-of-parts + shader language**, not hand-modeled scenes: modular cliff/rock sets with triplanar blending, scatter (ProtonScatter-style), macro color variation, strata shaders, decals, atmosphere cards.
- **Hero vistas** are authored (camera-composed), with the rest procedural but art-directed.
- **Budgets:** hub ≤ 100 draw calls; open region ≤ 150 on Low (reduced via impostors/LOD/instancing; the last audit saw 150-180 in combat, which we fix, not excuse).

---------------------------------------------------------------------------------------------------------------------

## F. Technical foundation (rebuild the skeleton, port the proven organs)

### F1. Engine and rendering

- **Godot 4.7 stays** (creator direction; the creator is separately building an engine and will hand it over; we keep game code and data **engine-agnostic at the boundary**: gameplay logic in plain GDScript modules + JSON/Resource data, rendering behind thin interfaces).
- **M0 spike: Compatibility vs Mobile renderer on the creator's phone** (Galaxy S25, Adreno 830). Compatibility works today; the Mobile (Vulkan) renderer may give better lighting/shadows/instancing at equal cost on modern GPUs. Decision by measurement, with Compatibility as the fallback path for older devices.
- **Tiers:** *Flagship* (Adreno 8xx / A-series): 60 fps, Medium. *Mid* (Adreno 6xx/7xx): 30 fps, Low. *Legacy*: Lite (reduced draw distance, no post). The phone report tool measures all three.

### F2. Architecture ("clean skeleton")

- **Layers:** `core` (services: Events bus, Save, Settings, Perf, Quality, Audio, Input) -> `sim` (Ledger, Region State, Bonds, Promises, Rivals, Era; pure logic, headless-testable) -> `gameplay` (character controller, combat, abilities, perception/Field Notes, interactions) -> `world` (streaming, regions, settlements) -> `ui` (screens built from one design system) -> `content` (data: canon, regions, species, quests, dialogue).
- **Component nodes + Resource definitions** instead of giant scene scripts: `Actor`, `Health`, `Knack`, `Perception`, `Interactable`, `Spawner`, `StateMachine`. Species, abilities, items and regions are `Resource`/JSON definitions validated at build time.
- **Deterministic sim:** Region State and Ledger rules run headless with seeded RNG; the harness replays whole descents in CI.
- **Open world streaming:** regions are chunked (cells ~64 m) with async load, impostors for far props, a navigation grid per cell, and a hard frame-time budget per frame for spawns/loads. Existing "one enemy created per frame" rule generalizes.
- **Save system:** versioned schema, autosave on safe points, never mid-combat or mid-dialogue; migration tests. Debounced saves are already built.
- **UI framework:** one design system (type scale, color tokens, button/panel components, safe areas, left-handed layout, accessibility: reduce flashing, text size). One owner. No more layout hacks per screen.
- **Dialogue:** the freeze-the-world-to-a-still trick from v0.14.1 is kept as a *service* (`WorldFreeze`) used by dialogue and full-screen menus. Dialogue runs from a validated data format with Ledger-aware conditions.

### F3. What we port, what we rebuild, what we retire

| Keep and port (proven, tested) | Rebuild cleanly | Retire |
|---|---|---|
| Ledger, Rivals, Bonds, Promises, Reactions (310 tests) | Player controller and camera (to Genshin-class feel) | Kit-bashed placeholder world meshes |
| Canon data: canon.json, codex, gear, regions, NPC data, validators | Combat framework as components (port ability logic) | Monolithic `level_*`/`hub_*` scripts (split into components) |
| QA harness (scripted touch), Perf reporter, Quality presets | UI (one design system), hub, HUD, Gate Map | Per-scene one-off lighting hacks |
| Explore/minimap/fast-travel logic (from last pass; re-skinned) | Region streaming + world pipeline | Scripted modeling pipeline for characters |
| Ability icons (procedural vector), toast queue logic | Species/ecology/Field Notes (new) | Reference-fidelity tooling (kept in archive) |

Porting rule: *a module returns only if it has tests, an owner and a place in the new architecture.*

### F4. Performance budgets (enforced by CI where possible)

| Metric | Flagship Medium | Mid Low |
|---|---|---|
| Frame time | 16.6 ms | 33.3 ms |
| Draw calls (open region) | ≤ 200 | ≤ 120 |
| Triangles on screen | ≤ 350k | ≤ 150k |
| Script time | ≤ 4 ms | ≤ 6 ms |
| Hitch (>50 ms) | 0 per minute in steady play; ≤ 1 per load | same |
| Memory (video + tex) | ≤ 700 MB | ≤ 450 MB |
| Cold start to input | ≤ 6 s | ≤ 10 s |

Real-device numbers come from the in-game performance report on the creator's phone. The software-renderer numbers are used only for *relative* regressions.

### F5. Tools to build early (they make everything after cheaper)

1. **Import Doctor** (validates delivered models).
2. **Golden-path bot:** plays the first 20 minutes through real touch input, takes screenshots, checks no script errors/hitches/draw-call regressions; runs per build.
3. **Region Recipe editor** (data validation + preview scene).
4. **Look-dev scene** (character on neutral + region lighting) for art review.
5. **Telemetry capture** (phone report → file → harness readable) for tuning loops.
6. **Delivery pipeline:** see Part G.

---------------------------------------------------------------------------------------------------------------------

## G. How we work (the process that keeps this from happening again)

### G1. Roles (agents) and ownership: *one owner per subsystem*

| Role | Owns | May not touch |
|---|---|---|
| **Lead / Director (me)** | Plan, integration, gates, creator communication | Feature code except trivial fixes |
| **Gameplay Engineer A** | Controller, camera, combat, abilities | UI, world art |
| **Systems Engineer** | Ledger/Region State/Bonds/Promises/Era/Save | Rendering |
| **World Engineer** | Streaming, regions, spawners, navigation, Field Notes hooks | Combat internals |
| **UI/UX Engineer** | Design system, HUD, hub, menus, onboarding | World, combat |
| **Technical Artist** | Shaders, lighting, kits, VFX, performance of visuals | Gameplay |
| **Content/Canon Editor** | Data, codex, quests, dialogue, lore checks (when un-paused) | Code |
| **QA/Playtester** | Golden-path bot, bug reports, fun/clarity tests | Fixing (reports only) |
| **Producer (Lead)** | Roadmap, scope, risks | |

Agents are **limited by weekly usage**, so each task is small, written down, and survives a restart (snapshot commits, tickets, handoff notes).

### G2. Gates every merge must pass

1. **Automated:** `tools/validate.sh` green; new logic has tests; no new script errors in the golden-path run.
2. **Perf:** draw-call/primitive/script-time budgets for the affected scene, measured; no new hitches.
3. **Feel (for gameplay changes):** a phone playtest note from the creator or a measured benchmark (latency, hit-stop, input buffer).
4. **Clarity (for UI/loop):** the five-minute test passes (Part C10) with fresh eyes.
5. **Look (for art):** before/after sheets at 3 aspect ratios; characters pop; no regression.
6. **Canon:** lore checks (spelling/American English, designs unchanged, Mystery Rule).

A failing gate means the change is reverted or fixed. No exceptions, so that "a pass ruined a lot" cannot persist.

### G3. Branching and releases

- `main` is always playable. Feature branches per ticket; short-lived. Release branches tagged `v0.x.y`; **every tag is archived** and can be restored.
- Weekly release train: one integrated build for the creator, with a one-page change log and "what to test."
- **Delivery (needs your decision; Part K):** the 30 MiB limit is a chat limit, not a game limit. Best path: GitHub Actions builds a zip on every push and publishes it as a Release you download on your phone (works for files up to 2 GB). This needs the repo set to private (it is public now) and permission to add the workflow.
  Alternatives: Git LFS plus branch zip; or I keep attaching trimmed zips in chat.

### G4. Tests with real people

- Phone playtests of every milestone build: you send the performance report screenshot plus three lines (what lagged, what confused you, what felt good).
- Fresh-eyes tests (friends/family) at M2, M3, M5: record the five-minute loop test.
- Metrics: time to first input, time to first creature, goal-restatement test, session length, return rate.

### G5. Documentation: one truth

- `design/AAA_PLAN.md` (this), `CORE_LOOP.md`, `ART_BIBLE.md` (E), `TECH_ARCH.md` (F), `CANON.md` (the creator's bible stays the authority), `CHANGELOG.md`.
- Old docs move to `design/archive/`. Conflicts are resolved in favor of the bible, then this plan.

---------------------------------------------------------------------------------------------------------------------

## H. Roadmap with gates (milestones, not dates)

Sizing is relative (S ≈ 1-2 work sessions, M ≈ 3-6, L ≈ 7-14, XL ≈ 15+). Each milestone ends with a build **you** play on your phone and a gate decision: *go / fix / change plan.*

### M0 — Foundation and proof (L)
- Archive/restore point (done), new folder skeleton (`core/sim/gameplay/world/ui/content`), docs consolidated.
- **Delivery pipeline** resolved (G3). **Phone telemetry** pipeline resolved.
- **Spikes (measured on your phone):** renderer comparison; chunked streaming test; 150-prop scatter at budget; 20-character crowd; outline/toon shader cost; world-freeze service.
- **Import Doctor v1** and the **Model Spec** package ready to hand to your outsourced artists.
- **Gate:** budgets proven on the S25 for Medium/Low; delivery pipeline works; you approve the Model Spec.

### M1 — "The Toy": feel prototype (M)
- Greybox arena with Aruun placeholder: movement, camera, dash, 3-hit combo, one Knack, one enemy, hit-stop, camera kick, input buffering.
- Metrics: input-to-visual latency, hitch count, framerate on three device tiers.
- **Gate:** *five minutes of this feels good on a phone with zero content.* If not, we iterate here until it does. Nothing else starts.

### M2 — Core loop in greybox (L)
- One small greybox region slice with: a landmark, 3 species (skitter mites, plate beetles, dust grazers), Field Notes with Reads and Interpretation, the 8 verbs partly (Fight, Contain, Leave, Build one span, Negotiate stub), a Gate, a mini Terrarium (arrive, debrief, Habitat for one captured species).
- Ledger drives a visible change on the next descent.
- **Gate:** the five-minute test with fresh players; they can state the loop; the region state change is noticed.

### M3 — Vertical slice 1: Terrarium One + Red Reaches "Fracture Valley" (XL)
- 20-25 minute Descent, authored: Aruun's first bond arc beats, Mara, Handler tutorial, the Red Span set-piece, a Rival, one boss.
- Real art pass: look-dev, kits, VFX, UI design system, audio hooks; outsourced Aruun/Mara if delivered, placeholders otherwise.
- **Gate (the AAA bar):** feel, clarity, look, perf and canon gates all pass; you sign "this is the game."

### M4 — Squad and second voice (L)
- Cigarra and Mara, tag-swap, team-up, Premonition counter windows; the Canopy Fold *mini-slice* to prove "each world feels unique" (verticality).
- **Gate:** the Canopy slice plays unlike Red Reaches in traversal, palette and encounters.

### M5 — Systems layer (XL)
- Habitat chains and species needs, Embassy Hall, Region State simulation, Promises and Bond tiers, Rival adaption, Expeditions, Micro-Descents, Era 1 structure and Crisis.
- Tools: Region Recipe editor, content validators, golden-path bot extended.

### M6 — Content production (XL, parallelizable)
- Lumen Depths; remaining bonds in tiers; creatures (10-14 per region); settlements; quests (the paused lore/quest/dialogue work resumes here, using the lore rewrite you provide).

### M7 — Alpha (L) / M8 — Beta (L) / M9 — Release candidate (M)
- Alpha: all Era 1 content playable; balance pass; accessibility; save safety.
- Beta: external playtest, telemetry, performance on a device matrix.
- RC: store builds, privacy and legal (patent review for Rivals), credits and licenses, onboarding polish.

### Always-on lanes
Performance (every milestone), Audio (music slots filled by your tracks), Localization hooks (American English first), Accessibility, Security of saves.

---------------------------------------------------------------------------------------------------------------------

## I. Scope tiers (so we never promise everything at once)

| Tier | Contents | Status in plan |
|---|---|---|
| **Tier 1: launch-critical** | Terrarium One, Red Reaches (deep), Aruun + Cigarra bonds, squad of three, Field Notes/Interpretation, 8 verbs (core), Ledger/Region State, Habitat basics, golden-path polish | M0-M5 |
| **Tier 2: launch-target** | Canopy Fold, Lumen Depths, Nerit + one more bond, Embassy Halls, Expeditions, Rivals, Era 1 Crisis | M4-M6 |
| **Tier 3: post-launch eras** | Rainward, Briarwild, Frostbloom, Velvet Warrens, Pelagic, Thornmarch, Ember Expanse, remaining bonds, seasonal Eras, optional social Terrarium visits and co-op (needs a small server) | After M9 |

Cut order if scope pressure appears: Tier 3 stays out, then Expeditions, then Habitat Metamorphosis, then second region; **never cut feel, clarity or performance.**

---------------------------------------------------------------------------------------------------------------------

## J. Risks and mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Outsourced models arrive late or off-model | Med | High | Placeholders + Import Doctor + Model Spec + early look-dev frames; fidelity check against sheets |
| Feel never reaches target on phone | Med | Critical | M1 gate is a hard stop; iterate on real device |
| Open-world performance on mid devices | High | High | Streaming spike in M0, budgets in CI, impostors, Low preset designed first |
| Scope creep from the 25-system master plan | High | High | Tier table; one new system only after prior gates pass |
| Agent usage limits stall work | High | Med | Small tickets; handoff notes; snapshot commits; Lead can do critical-path work |
| Public repo exposes IP | Known | Med | Make private (Part K) |
| Rival system overlaps a patent | Low-Med | High | Different structure (documented) + IP attorney review before launch |
| Lore rewrite changes canon mid-build | Med | Med | Canon is data; validators; diff-and-flag process |
| Custom engine hand-off diverges | Low | Med | Engine-agnostic boundary; data/logic separated from rendering |

---------------------------------------------------------------------------------------------------------------------

## K. What I need from you (decisions)

1. **Approve or edit this plan** (especially pillars C/D, the Era 1 scope, and the roadmap gates).
2. **Make the GitHub repository private**, then let me add the build workflow so you can download any size build on your phone. (Or choose an alternative in G3.)
3. **What did the last pass ruin?** (so I can compare against v0.14.1 and v0.13.x and fix or restore specific things; the archive branch has everything).
4. **Squad size:** 3 active (default) or 2?
5. **Control scheme:** Genshin-style (free camera, my recommendation) or keep the fixed 3/4 camera?
6. **Era 1 homelands:** Canopy Fold and Lumen Depths (my proposal) or others?
7. **Outsourced art:** who, what timeline, and which characters first? (I will send the Model Spec to give them.) Is Aruun first, as before?
8. **Lore rewrite:** when it lands, I will diff against canon data and flag contradictions. Do you want quest/dialogue work to resume at M6, or earlier for a specific character?
9. **Music:** send your tracks when ready; slots are reserved.
10. **Monetization intent** (premium, free-to-play with cosmetics, etc.). It does not change the first milestones but it shapes later systems.

---------------------------------------------------------------------------------------------------------------------

## L. The first week (if you approve)

1. Restructure the repo skeleton and consolidate docs. Port the tested sim modules (Ledger/Bonds/Promises/Perf/Quality).
2. Delivery pipeline (per your decision) and phone telemetry loop.
3. M0 spikes on your phone with built-in report screens: renderer, streaming, scatter, crowd.
4. Write the Model Spec package (PDF/MD) and Import Doctor v1 so your artists can start.
5. Start M1 "The Toy" immediately after the M0 gate.

I will stay in the Director role: planning, integrating, measuring, and reporting each gate with screenshots and numbers.
