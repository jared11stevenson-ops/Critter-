# CRITTER v2 — Moves taken from the lore (Lead, 2026-10-11)  — BINDING for the Combat Engineer and animators

**Rule (creator):** each character's moves come from what the lore already says they can do and who they are. Nothing here is invented from outside the bible.
Sources: `game/canon/canon.json` abilities (already derived from the lore; used verbatim for Aruun and Cigarra) and the character sections in
`design/v2/lore_text/LORE_BIBLE_v12.txt`. Where the lore names a Knack but not a move, the move is the *direct mechanical expression of that Knack and its stated cost*,
cited by line. Every move must be traceable to a quote. The shared system (Strike/Guard/Grab/Dodge triangle, stamina, poise, Yield, Last Stand) still applies;
a character's flavor changes **how** those inputs look and behave. Numbers are tuned by the balance bot; names and effects are fixed here.

Legend: **[canon]** = existing ability in canon.json; **[lore:L###]** = line in the lore text.

## 1. Aruun — "The Reacher" (giraffe beetle · psionic mace Morrow · Rage)  — CREATOR FOCUS: his whole kit is built on exactly these three things
**Design pillars (creator):** (1) the **psionic mace** Morrow is a living partner and the center of every move; (2) the **giraffe beetle** body decides his reach and rhythm (long neck/reach, heavy front, red-and-black beetle build per the reference sheet); (3) **Rage** is the signature system: power paid for with his own body.
Lore hooks: Morrow "can redirect in flight, return to Aruun and transmit impact sensation. Sometimes it appears to move before he commands it" [lore:L424]; Rage = "deliberate physiological overdrive.
He suppresses his body's protective limits. Greater strength therefore means greater self-damage" [L439-445]; Red Span: "anchors Morrow and uses their bond to redistribute structural force through his own body. For eleven minutes he carries part of a bridge";
Burden Architecture: "a structure should sacrifice itself before sacrificing the people inside"; "His shell fractures."
| Slot | Move | Source | Behavior |
|---|---|---|---|
| Strike | **Morrow combo** | [canon] "three-strike mace combo; the last swing knocks enemies back" | 3-hit chain, finisher knockback (ring-out) |
| Heavy | **Morrow overhead** | [lore:L424] impact transmitted | slow, big, guard-crush |
| Guard | **Shell brace** | [lore] shell fractures / Burden Architecture | blocks with plates; each big block cracks a **shell plate** (visible; plates absorb damage before Vitality, then are gone for the bout) |
| Grab | **Morrow drag** | [canon] Gravity Pull concept | short-range pull-and-slam |
| Ability 1 | **Reaching Strike** | [canon] cooldown 6s | Morrow extends through the psionic link: long-range heavy; "shatters cracked Thoughtstone" (breaks arena cracks) |
| Ability 2 | **Gravity Pull** | [canon] cooldown 10s | Morrow floats ahead, drags enemies together, slams down |
| Resource | **Beetle Rage / Strain** | [canon] cooldown 18s; [L439] | **Rage is a central bar:** it builds as he takes and deals hits; in Rage he is faster and hits harder, protective limits are off (guard-crush on every swing, super-armor on heavies) and he **pays Strain from his own Vitality every second**; he can end it early. Rage never kills him: it stops at 1 Vitality, which is when the Last Stand and the Yield/Last Stand choice matter most |
| Passive | **Morrow moves first** | [lore:L426] "Sometimes it appears to move before he commands it" | on a perfect parry (and at random low odds in Rage) Morrow launches an automatic counter-strike without input |
| Last Stand | **Carry the Bridge** | [lore: Red Span] | plants Morrow and absorbs incoming force into his body for a few seconds (no knockback, damage stored), then releases it as one huge hit |
Rival-species chapter and story beats: see ROSTER.md.

## 2. Cigarra — "The Oracle Hopper" (Brazilian treehopper · psychic premonition · mind control)  — CREATOR FOCUS: her kit is built on exactly these three things
**Design pillars (creator):** (1) the **Brazilian treehopper** body: the crown of branching black spheres is her instrument and her weapon, with the translucent wing cloak for leaps; (2) **psychic premonition**: she sees the enemy's next move before it happens; (3) **mind control**: she bends the enemy's actions (Psychic Interference).
Lore hooks: "She experiences noise. Crowded environments can produce dozens of competing outcome-images" [L330-334]; fears "choosing an action because she saw it and thereby causing the future she feared";
"A future seen is a future touched" [Bk XIV]; uses "humor and apparent instability as psychological armor"; "she improvises around plans."
| Slot | Move | Source | Behavior |
|---|---|---|---|
| Strike | **Bad Thought** | [canon] "flicks a crown sphere and fires a distorted psychic object" | fast ranged flick; combos; her light attack |
| Heavy | **Crown Barrage** | [lore] branching black-sphere crown | slower multi-sphere volley on branching paths |
| Guard | **Cloak fold** | [lore] translucent treehopper-wing cloak | wing cloak guard with the longest parry window (she sees it coming) |
| Grab | **Puppet Thought** (mind control) | creator direction + [lore: Psychic Interference] | a psychic grab (beats Guard): her crown spheres flare (a clear tell, interruptible by hitting her or breaking line of sight with a dodge). On success the enemy is **compelled for about 1.2 s**: Cigarra picks one forced action: *stumble toward the edge (ring-out risk)*, *drop guard and stagger*, or *strike the empty air (whiff and be open)*. Hits on a high-Poise enemy only shorten the compel. |
| Counter | **Brain Skip** | [canon] cooldown 9s | the counter she gets when she dodges through a Premonition ghost: the target loses a fraction of time, its action jumps forward and it stumbles |
| Ability 1 | **Premonition** | [canon] cooldown 12s | translucent future ghosts show where the enemy will move or attack; dodge through one to counter |
| Ability 2 | **False Memory** | [canon] cooldown 14s | mind control by illusion: a hallucination the enemy believes and attacks (it chases and strikes the decoy for a few seconds) |
| Mobility | **Grasshopper Thought** | [canon] | crouch, then launch great distances; the cloak opens to steer (her Dodge/gap-closer) |
| Resource | **Future-Noise** | [lore:L330] | builds as she uses Premonition/False Memory; at high noise her predictions contradict (random ghost decoys appear) until it decays |
| Combo | **Probable Impact** | [canon] with Aruun | exists as a team-up for later (not in 1v1) |
| Last Stand | **A Future Touched** | [Bk XIV quote] | for a few seconds every enemy attack is ghosted early and every dodge counters automatically; ends in Future-Noise overload |

## 3. Bramvex — "The Quiet Command" (Camouflage / Sensory Adaptation / Tactical Terrain Use; weapon: "Diplomacy")
Lore hooks: "enormous thorned weapon earns the nickname Diplomacy" [L~810]; "Camouflage is ecological before it is military. To be visible can mean vulnerability"; a sergeant who asks "Who has eaten? Which route is safe? Where is the retreat?";
"He spends nineteen days observing. He maps routines, doors, cameras... On Day 20 he escapes"; "plans that assume infrastructure will fail"; "Cigarra Holes: deliberate blank spaces in plans" [Bk XIV].
| Slot | Move | Source | Behavior |
|---|---|---|---|
| Strike | **Diplomacy swings** | [lore] thorned weapon | long thorned weapon: long reach, medium speed, thorn hits cause bleed |
| Heavy | **Diplomacy, final offer** | [lore] nickname | slow overhead; guard-crush |
| Guard | **Stand firm** | [lore] sergeant, field equipment | steady block; perfect guard grants **Intel** |
| Grab | **Detain** | [lore] he restrains/frees detainees | thorn-lock hold; short throw |
| Passive/Resource | **Observation (Intel)** | [lore] nineteen days observing | every bout he learns the enemy's habits: each repeated enemy move he has seen gets a **reduced tell time penalty** (his reads improve over the bout; reaches full on "Day 20") |
| Ability 1 | **Ghost** (camouflage) | [lore] Camouflage / Sensory Adaptation | becomes hard to target for a few seconds; the next hit is a guaranteed ambush crit |
| Ability 2 | **Ground Prep** (terrain use) | [lore] Tactical Terrain Use | plants thorn lines and chokepoints that slow or hurt; enemies are funneled |
| Utility | **Cigarra Hole** | [Bk XIV] | a deliberate gap: a short unpredictable evade he can chain out of |
| Last Stand | **Day 20** | [lore: escape on Day 20] | breaks out of any hold or stun, clears debuffs, and unleashes a planned counter-assault using everything he observed |

## 4. Scarlith — "The Fermented Kingpin" (Fermentation / Decomposition / Cultivation)
Lore hooks: "Age can create value. Controlled decay can preserve. Waste can become food" [Bk VIII]; "everything has value"; Undermarket broker; "finding abandoned value vs declaring something abandoned";
red-velvet-mite design with cheese/pirate flavor; "decomposition as transition. Nothing is worthless merely because its first use ended."
| Slot | Move | Source | Behavior |
|---|---|---|---|
| Strike | **Culture jab** | [lore] fermentation | quick jabs that apply a **Culture** stack to the target |
| Heavy | **Aged Smash** | [lore] "age can create value" | slow strike whose damage scales with the Cultures on the target |
| Guard | **Rind guard** | [lore] cheese flavor | cheesy rind block; parry spoils the attacker's next move |
| Grab | **Barter** | [lore] broker | snatch and swap: steals one buff from the enemy and gives it a penalty |
| Ability 1 | **Ferment** | [lore] Fermentation | Culture stacks ripen over time: damage over time that grows the longer it is left; at ripe it bursts |
| Ability 2 | **Decompose** | [lore] Decomposition | rots armor and guard: lowers the target's Guard and Poise for a time |
| Resource | **Cultivate** | [lore] Cultivation | grows fungus patches in the arena that feed him Brew and heal him; the enemy can trample them |
| Passive | **Waste Not** | [lore] "waste can become food" | converts damage he takes into Brew |
| Last Stand | **Aged to Perfection** | [lore] age creates value | instantly ripens every Culture on the enemy |

## 5. Mollusk — "The Weight of Tomorrow" (Temporal Inertia)
Lore hooks: "Mollusk does not stop time. He increases resistance to change. A falling object falls more slowly. A fracture spreads reluctantly. An impact can remain incomplete. The effect eventually resolves. Nothing is erased" [L525-540];
"Delay is useful only if you use the delay"; Borrowed Seconds: "Every second he creates is a debt" [Bk XIV]; shell memory marks; "holds a collapsing structure in an unfinished state"; love of forklifts.
| Slot | Move | Source | Behavior |
|---|---|---|---|
| Strike | **Slow shell shove** | [lore] body/shell | heavy, deliberate body strikes (low speed, high poise) |
| Heavy | **Gathering blow** | [lore] inertia | the heavy keeps growing while held (resistance accumulates) |
| Guard | **Hold** (inertia guard) | [lore] "an impact can remain incomplete" | blocks, but the damage is not erased: it is **delayed** and lands later unless he spends Borrowed Seconds |
| Grab | **Lift** | [lore] forklifts | hoist-and-set-down throw |
| Ability 1 | **Inertia Field** | [lore] resistance to change | a zone where the enemy's attacks and movement slow (their active frames lengthen) |
| Ability 2 | **Borrowed Seconds** | [Bk XIV] | gain extra time now (longer parry windows / extra dodge), repay as a debt later (slower recovery) |
| Passive | **Shell Memory** | [lore] shell records journeys | each bout survived adds a carved mark: permanent small armor bonus (ties to the survival theme) |
| Last Stand | **Everything Arrives at Once** | [lore] delayed effects resolve | releases every delayed hit and held impact at once |

## 6. Zephyr — "The Nectar Seeker" (Motion / Atmospheric Disturbance / Pollination)
Lore hooks: "Zephyr treats rules as games but treats promises as sacred"; "Promise Law: wording matters, intent matters"; "loves loopholes"; detention "repeatedly fails" [L560-585]; courier: "crossing spaces quickly is both talent and joy"; hummingbird-hawk-moth hover.
| Slot | Move | Source | Behavior |
|---|---|---|---|
| Strike | **Flutter strikes** | [lore] motion | very fast light strikes from hover; ends with a side step |
| Heavy | **Delivery** | [lore] courier | a rushing heavy that crosses the arena |
| Guard | **Loophole** | [lore] "loves loopholes" | a dodge-block: slips through a strike if timed (small i-frames), poor vs heavy |
| Grab | **Catch** | [lore] | seizes in mid-air and releases for a ring-out |
| Ability 1 | **Gust** | [lore] Atmospheric Disturbance | knocks back, pushes projectiles and ring-out; or pulls |
| Ability 2 | **Pollen** | [lore] Pollination | a cloud that marks the enemy (slows and reveals); marked enemies take bonus damage from Zephyr |
| Mechanic | **Promise** | [lore] Promise Law | she can **declare** her next attack; if she follows through exactly, bonus damage and stamina refund; if she breaks it, she pays stamina (wording matters) |
| Last Stand | **A Promise Kept** | [lore: promises sacred] | declared sequence that cannot be interrupted or dodged for its duration |

## 7. Nyxaris — "The Frostbloom Weaver" (Cryogenic Silk / Venom)
Lore hooks: silk "can be bridges, traps, insulation, records, nurseries and territorial markers"; "Pattern communicates authorship"; "unusually cold-reactive"; "turn fragile beauty into controlled space"; "patient until a boundary is crossed"; "Who gave you permission?";
Cold Archive: "frozen silk preserving testimony" [Bk XIV]; Nyxaris v. Helix; costs: "cannot endlessly generate cryogenic silk without replenishing the minerals" [Bk III §12].
| Slot | Move | Source | Behavior |
|---|---|---|---|
| Strike | **Silk lash** | [lore] silk | whip-like lashes, mid reach |
| Heavy | **Frost lance** | [lore] cold-reactive silk | slow, freezes on hit (chills) |
| Guard | **Silk screen** | [lore] "insulation" | woven barrier block |
| Grab | **Cocoon** | [lore] silk as trap | command grab wrapping the target; ring-out by being dragged |
| Ability 1 | **Boundary** | [lore] "patient until a boundary is crossed"; "territorial markers" | draws a silk border in the arena; crossing it triggers a freeze snare |
| Ability 2 | **Venom Fang** | [lore] Venom | poison damage-over-time with a visible ticking stack |
| Counter | **"Who gave you permission?"** | [lore quote] | counter-stance: punishes a strike that enters her space |
| Resource | **Silk reserve** | [Bk III §12] | silk is limited; running low forces melee and fewer webs until it regenerates |
| Last Stand | **Cold Archive** | [Bk XIV] | the whole arena becomes living frozen silk: enemy slowed, her moves free of silk cost |

## Rules for implementation
1. Every move has `lore_source` in its JSON (the tag and quote key above) and the validator rejects moves without one.
2. If a mechanic needs extending, document it in SCHEMA.md; do not add moves outside this document without the Lead's approval.
3. Visual style stays per ART_BIBLE; the move's silhouette comes from the character's own body and reference art (e.g., Cigarra's crown spheres are her projectiles; Aruun's Morrow is his weapon).
