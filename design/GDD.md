# CRITTER — Vertical Slice GDD: "The Red Span Survey"

Source of truth: `CRITTER_Master_Lore_Bible_v12`. Every element below cites the lore it comes from.
If this document and the bible disagree, **the bible wins** and the lead fixes this document.

## 1. Pillars
1. **Canon-exact characters.** Model sheets are binding (Bible §61). Characters are rendered from the
   approved sheet art itself (HD-2D: painted canon billboards in a stylized 3D world). Never humanize,
   never simplify.
2. **Knacks have costs** (§12, §59). No mana bars. Aruun spends his own body; Cigarra drowns in future-noise.
3. **Understanding is a resource** (Book XXXII). Scanning tells you whether something is wildlife,
   a person, a resource or a threat — and opens non-violent solutions.
4. **Persistent consequence** (§54, §55, Design Law). The slice ends with a choice that physically
   changes the player's Terrarium and the region's world state.
5. **Mobile-first feel.** One thumb moves, one thumb fights. Every action readable on a 6" screen.

## 2. Core loop (Bible Book XXXII, verbatim)
DESCEND → EXPLORE → UNDERSTAND → INTERVENE → RETURN → BUILD → LIVE WITH CONSEQUENCES → DESCEND AGAIN

## 3. Premise
The player is a newly certified **Handler** (§16, §51) at **Terrarium One** (§19). A Dominion-funded
Thoughtstone prospecting operation in the **Red Reaches** (§23) is shaking the foundations of an
ancient Spanwright bridge, the Red Span's sister crossing, **the Ochre Span**. Aruun joins because bridges are
at stake. Cigarra joins because Dexter Mane's name is on the permit and his decisions produce
"unusually sharp probability branches" (Book XXX). Mara Venn runs the expedition from the Gate.

Timeline: First Contact Era, after the Terrarium Standoff and during Nyxaris v. Helix. The First Ten
already know each other (they met on Earth, §57).

## 4. The Handler (player)
The Handler is never shown as a model; the player *is* the Handler: the camera, the tablet UI, the
voice the characters address. Dialogue addresses the player as "Handler". The HUD is framed as the
Handler's field tablet (Scale-State instrumentation). In the field the player directs and directly
controls the Critters they are partnered with (Contract Bonding, §17 — never "owned").

## 5. Playable partners
Both partners are on the field. The player controls one; the other is AI-driven. Tap portrait to swap.

### Aruun — The Reacher (BRU-004)
- Role: melee / tank. HP 420. Move 4.6 m/s. Height 2.4 m.
- **Basic — Morrow combo**: 3-hit mace combo, wide arcs, 22/22/40 dmg, last hit knocks back.
- **Reaching Strike** (CD 6s): Morrow extends; a 9 m line strike, 60 dmg, breaks *cracked Thoughtstone*.
- **Gravity Pull** (CD 10s): Morrow floats to a point 6 m ahead, pulls enemies in (2 s), slams for 45.
- **Beetle Rage** (CD 18s): 8 s overdrive: +50% damage, +25% speed, hits stagger. **Cost: Strain**
  — Aruun loses 4% max HP/s while raging (Bible: "Greater strength therefore means greater self-damage").
- Traversal: breaks cracked Thoughtstone boulders; holds collapsing structures (scripted Burden moments).

### Cigarra — The Oracle Hopper (PSI-017)
- Role: control / mobility. HP 240. Move 5.4 m/s. Height 1.65 m.
- **Basic — Bad Thought**: flicks a crown sphere; auto-aimed psychic bolt, 16 dmg, 14 m range.
- **Premonition** (CD 12s): for 5 s, enemies show translucent *future ghosts* of their next attack;
  time slows to 70%; dodging through a ghost grants a guaranteed critical counter. (Sheet: "Briefly
  shows translucent future ghosts indicating where enemies are about to move or attack.")
- **False Memory** (CD 14s): creates a hallucinated decoy (a Cigarra echo) for 5 s; enemies target it.
- **Brain Skip** (CD 9s): target loses a fraction of time — its current action is skipped and it is
  stunned 1.6 s, 30 dmg.
- **Grasshopper Thought** (traversal): crouch-launch across marked gaps (leap points).
- **Cost: Future-Noise** (Bible §22 "Cost of Premonition"): every ability adds noise (0–100). Noise decays
  6/s when not casting. Above 60 the screen gains chromatic noise and false ghosts; at 100 she is
  *overwhelmed* for 3 s (cannot cast, slowed). Noise is her resource and her risk.

### Combo (relationship-gated, Book XXXII "Characters who learn to trust one another can develop
cooperative techniques")
- **Probable Impact**: unlocked after the Waystation conversation. When Cigarra's Premonition is active,
  Aruun's Gravity Pull slam deals +100% and stuns. Mirrors Bramvex's "Cigarra Holes": plans with
  deliberate gaps for her to exploit.

## 5b. Dash (both partners)
Short evade (Aruun 3.5 m, Cigarra 5 m, Cigarra's is a hop). 0.25 s invulnerability, 1.2 s cooldown.
Dashing *through* a Premonition future ghost triggers the counter (next hit = guaranteed critical ×2.5,
plus a 0.35 s slow-motion beat).

## 6. Handler tools (shared buttons)
- **Scan** (no CD, 0.4 s): slows time, overlays classification on every nearby organism/object:
  `WILDLIFE · SAPIENT · SACRED · RESOURCE · DOMINION ASSET · STRUCTURE`. First scan of a species writes
  a Codex entry and reveals behavior (e.g. "Agitated by resonance pylon vibration").
- **Containment** (contextual): a wild, non-sapient organism under 30% HP can be contained (Wild
  Containment, §17). Contained specimens go to the Terrarium. Sapients can never be contained — the
  scanner refuses (law + lore).

## 7. Region: The Red Reaches (Bible §23, visual ref #28 "Aruun Region — The Reacher Lands")
Plateaus, mineral deserts, enormous fracture valleys. Red/orange strata, sparse flat-topped trees,
bone structures, beetle-worm rock. Ringed planet in the sky (World Assets sheet).

### Level beats (layout in `game/world/red_reaches/layout.json`)
1. **Gate Pad** — arrival. The *Tilt* (scale sickness, §4) screen effect. Mara on comms. Movement tutorial.
2. **Fracture Valley** — first wild encounter (Skitter Mites). Attack + swap tutorial. Scan tutorial.
3. **The Gap** — Cigarra's Grasshopper Thought leap; she drops a Spanwright rope span for Aruun.
4. **Spanwright Waystation** — ruins; Old Road marker stone (§9, scan → codex). Dust Grazers (passive,
   keystone wildlife: harming them sets `grazers_harmed`). Aruun/Cigarra conversation → combo unlock.
5. **The Thoughtstone Fall** — cracked boulder; Aruun's Reaching Strike breaks it.
6. **Drill Site** — Dominion survey drones + agitated Plate Beetles + 3 resonance pylons. Scanning a beetle
   reveals the pylons cause the agitation. Destroying pylons calms beetles (they leave — non-violent path).
7. **The Ochre Span** — ancient bridge. Mid-crossing, the drill shakes it: **Burden moment** — Aruun
   anchors Morrow and holds the span (hold button) while Cigarra gets the convoy marker across (echo of
   Red Span, §23).
8. **Boss: AUGUR-7 Deepcore Rig** — Dominion excavation rig drilling into the foundation. Phases:
   (1) drill slams + drones, (2) exposes coolant vents, Thoughtstone shards erupt, (3) overdrive drill
   beam sweep. Defeat shuts it down.
9. **The Choice** at the foundation:
   - **Repair** (Burden Architecture): spend the Thoughtstone you carry to brace the foundation with
     Aruun. +Aruun trust. Unlocks *Burden Bridge* in the Terrarium. World state `ochre_span = braced`.
   - **Extract**: hand the Thoughtstone cache to the Dominion contract. +Resources, +Dominion standing,
     Aruun trust drops, world state `ochre_span = failing`.
   Either way: **a Thoughtstone fragment aligns itself toward Morrow** (Bible XIV — the mystery hook).
10. **Return** through the Gate.

## 8. Terrarium One (hub) — Bible §19, §20, §48, §55
A diorama of the Common: the Common Table (built from discarded Habitat material), translation boards,
Nerit's living lights, market stalls, the Gate ring, the Habitat Wing. First Ten members appear around
the Common (ambient, canon sprites): Mollusk, Bramvex, Nerit, Zephyr, Nyxaris, Pharilux, Solmara,
Scarlith. Tap hotspots:
- **Common Table** — story conversations (pre-mission briefing, post-mission reactions to your choice).
- **Gate** — Descend.
- **Habitat Wing** — BUILD: a Habitat chain puzzle for each contained specimen (§13).
- **Field Codex** — species, characters, places, mysteries (Thoughtstone, Pharilux 1897, Moon Question…).
- **Mara's Lab** — Mara Venn, expedition lead (Book XXX, ref #17).

## 9. Habitat chains (Bible §5, §13)
Each specimen needs a chain: Substrate → Symbiont → Climate → Anchor. Example Plate Beetle:
Red Reach soil + Lichen mat + Heat lamp + Scale Anchor (tuned). Wrong pieces → stress; complete chain →
habitat thrives and the creature shows behaviors. Modules cost materials found in the field
(Reach Soil, Lichen Culture, Thoughtstone Dust, Salvage).

## 10. World state persisted
`ochre_span`, `grazers_harmed`, `pylons_destroyed`, `beetles_calmed`, `specimens[]`, `trust.aruun`,
`trust.cigarra`, `dominion_standing`, `codex[]`, `habitat`, `chapter`.

## 11. Mobile UX
- Landscape. Left half: floating joystick. Right: Attack (big), 3 abilities in an arc, Dash, Swap (portraits
  top-left), Scan (top-right), Interact (contextual, appears above attack).
- Ability buttons show cooldown sweep and cost (Aruun: red Strain tick; Cigarra: noise gain).
- Auto-aim to nearest target in facing cone; abilities aim along stick direction if held.
- 60 fps target on mid-range; Compatibility renderer.
- All text ≥ 22 px at 720p reference.

## 12. Canon cut list
- Scambril: **cut** (director ruling).
- Superseded sheets not used: Nerit (#37 humanoid), Mollusk (#22 grey), Solmara (#14), Mara photoreal (#5, #6).
