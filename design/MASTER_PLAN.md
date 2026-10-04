# CRITTER — Master Plan: the 25 systems (Lead, Oct 2026)

Direction from the creator: **sapient characters are the main thing the player acquires ("bonds")**; the lore is being rewritten (Lead
updates canon going forward); graphics get a full overhaul; Godot 4.7 target; mobile-first (Compatibility renderer, Low/Medium/High).
Everything below is data-driven and built on one shared memory: the **Ledger** (design/LEDGER_SPEC.md).

## The 25 (each cites where the idea comes from; none uses third-party code)

### A. World & structure (6)
1. **Gate Map** — S−1 drawn as a mosaic with enormous blank areas (bible §6); regions unlock by exploration. *(Fallout 2 world map)*
2. **Region Recipes** — one data file per homeland: ground, props, sky, creatures, music, encounters. New region = new data. *(Fallout 2 / Crimson Desert regions)*
3. **Descent Events** — ecology-driven encounter tables per biome (migration, Dominion convoy, stranded Critter, Old Road marker). *(Fallout 2 random encounters / WoW world quests)*
4. **Contact Eras** — each season is an Era with a Crisis and permanent Legacies; no borrowed power. *(Civ 7 Ages / WoW expansions)*
5. **World-State Affixes** — endless region runs with modifiers from the bible's list: Flood, Fire, War, Migration, Overgrowth, Disease, Extraction. *(Mythic+)*
6. **Micro-Descents** — 5–10 minute scalable runs with one companion who levels and carries gear. *(WoW Delves)*

### B. People & bonds (7)
7. **Bond Contracts** — acquire sapients through staged, character-specific trust quests built on their contradiction. *(Pokémon catching reimagined; Baldur's Gate companions)* — **engine built**
8. **Promises as game objects** — wording, letter vs spirit, permanent consequences. *(Zephyr's Promise Law)* — **engine built**
9. **Reaction Matrix + Camp** — companions react to what the ledger remembers; camp = the Common Table. *(Baldur's Gate)* — **engine built**
10. **Renown Tracks → allied recruits** — each culture's reputation unlocks Habitat modules and bondable characters. *(WoW Allied Races/Renown)*
11. **Era side-choice** — Coalition vs Dominion mid-Era, with side-exclusive bondable characters. *(Marvel Ultimate Alliance 2)*
12. **Embassy Halls** — each homeland gets a wing in Terrarium One that grows as you bond its members. *(WoW order halls)*
13. **Expeditions** — bonded characters not in your squad run Gate missions while you play. *(WoW Garrison followers)*

### C. Combat (6)
14. **Squad of three** with tag-swap cooldown + a leadership skill. *(Marvel Future Fight)*
15. **Knack Wheel** — a readable interaction chart by mechanism (Pressure crushes Silk, Light reveals Camouflage…) with ecological costs. *(Pokémon type chart)*
16. **Templated Fusion & Team-Up gifts** for every bonded pair, generated from the two characters' Knack palettes/verbs. *(MUA2 Fusions, Marvel Rivals Team-Ups)*
17. **Read-and-counter timing** — Premonition ghosts open counter windows. *(Crimson Desert)* — partly built
18. **Tactical Pause** — slow-time and queue partner orders. *(Baldur's Gate)*
19. **Priced Foresight** — spend Future-Noise to preview 2–3 ghosted outcomes of a choice or boss phase. *(Cigarra)*

### D. Base & ecology (3)
20. **Species-shaped needs** — Terrarium residents need what their bodies need (light cycle, vibration, privacy, warmth); unmet needs cost them in the field. *(Fallout 4 settlements + bible §8)*
21. **Habitat Metamorphosis** — non-sapient wildlife are the second collection; Habitat conditions decide their adult form. *(Pokémon evolution + bible metamorphosis)*
22. **Old Road Words** — markers teach Knack adaptations; skills grow with use. *(Skyrim Word Walls)*

### E. Memory & rivals (3)
23. **The Ledger** — shared memory for everything above. — **built, 52 tests**
24. **Ledger Rivals** — our own nemesis-style system: few rivals who remember how you fight, adapt, scar, and can be resolved by force, terms, exposure, release or a bond. — **built (core), 52 tests**
25. **Session Zero + Director** — choose tone sliders at the start (combat / story / exploration / puzzle); an adaptive Director paces encounters; advantage/disadvantage as the one readable rule. *(D&D)*

**Post-launch pool:** Terrarium Postcards, Moddable Atlas, Shared Crisis (needs a server), Scale Doors, Memory Echoes, selective destruction, Field Photography.

## Legal notes (not legal advice)
- Warner Bros. holds US patent 10,926,179 on the Nemesis System (granted Feb 2021, maintainable to 2035). Our Rivals follow different structural rules (see
  LEDGER_SPEC §7). **Have an IP attorney review before launch.**
- Licenses: MIT/Apache/BSD/CC0 OK; CC-BY needs credit; GPL/AGPL/EUPL/NonCommercial avoid. NobodyWho (EUPL-1.2) is excluded.
- Fallout/Skyrim/D&D/Marvel/WoW/Pokémon/Civ are *design references only*: no names, art, lore or code.

## Build order
| Phase | Scope | Status |
|---|---|---|
| 1 | Ledger + Rivals + Bonds + Promises + Reactions (engine), integrate into the slice: debrief panel, 2 rivals, Zephyr bond, reaction barks, Session Zero v1 | engine ✔ / integration → Agent 2 |
| 2 | Gate Map + Region Recipes + Descent Events + Micro-Descents (data + 1 more region) | data → Agent 3, runtime → Agent 2 |
| 3 | Squad of three + Knack Wheel + Fusion/Team-Up | Agent 2 + Agent 4 (VFX/anim) |
| 4 | Embassy Halls + Expeditions + Renown + Era side choice | Agent 2 + Agent 3 (content) |
| 5 | Needs + Metamorphosis + Old Road Words + Foresight + Tactical Pause + Affixes | Agent 2 |
| 6 | Era 2 content; the full graphics overhaul runs in parallel under Agent 1/4 | creator-triggered |

## Team assignments (this round)
- **Agent 2** (A): Phase 1 integration (spec §8), Session Zero v1, then Gate Map screen.
- **Agent 3** (provisional B): content + data — bonds/values/reactions for the First Ten, region recipes + descent events for 5 homelands, rival names/lines; every file must pass `tools/validate_data.py`.
- **Agent 4** (A−): Aruun model to match the reference art; Cigarra model + animation.
- **Agent 1** (B+): benched until the graphics overhaul is triggered.
