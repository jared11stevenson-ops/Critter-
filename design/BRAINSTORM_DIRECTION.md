# Brainstorm decisions & direction (Lead notes, Oct 4)

## Creator direction
- **Sapient characters are the main thing the player acquires ("bonds").** The creator is rewriting the lore; the Lead updates
  canon.json / codex / dialogue to match once the rewrite lands (diff old vs new, flag contradictions).
  The old bible rule "sapients are not collectible" is superseded by that rewrite. Fiction suggestion: acquisition = consent-based
  Contract Bonding (already in the bible), so the collect loop reads as earning trust, not owning people. Creator's call.
- Everything graphic gets a complete overhaul starting Oct 5.

## Ideas adopted from earlier brainstorms
- Fallout 2: Gate Map (S-1 mosaic w/ blank areas), region recipes (data), encounter tables ("descent events").
- Baldur's Gate: reaction matrix (companion x event barks), camp conversations at the Common Table, optional Tactical Pause.
- Marvel Future Fight: team of 3 w/ tag-swap cooldown, leadership skill, team-combo bonuses, saved squads. NOT: gear treadmill / Combat Power / pay-gacha.
- Crimson Desert: read-and-counter timing, distinct regions, set-piece sieges (quality targets, not code).
- Civ 7: Eras + Crisis + Legacy meta-layer.
- WoW: Delves-style companion runs, Legion order halls / personal artifact weapon, Mythic+ affixes, Renown/allied unlocks, housing, Warband-style
  cross-save unlocks, phasing for persistent region states, no "borrowed power" (Shadowlands lesson), skill-based traversal.
- Pokemon: simple legible interaction wheel + deep build layer, catching as core fantasy, evolution by conditions, Dex completion, Secret Bases,
  regional variants, trials instead of gyms, real-time battles (Legends Z-A), observation-based research (Legends Arceus).

## The 10 new ideas (see chat for detail)
1 Bond Contracts · 2 Embassy Halls + Expeditions · 3 Micro-Descents · 4 World-State Affixes · 5 Habitat Metamorphosis
6 Knack Wheel · 7 Field Photography · 8 Terrarium Postcards · 9 Renown Tracks + Allied Recruits · 10 Contact Eras (no borrowed power)

## Open questions for the creator
- Is Bond Contracts the right acquisition loop (vs reputation-only)? Which ideas go in the overhaul spec? Party size (2 / 3 active)?

---
# Final brainstorm session (Oct 4): open source, 5 reference games, revolutionary ideas

## Open source (verified this session)
- Godot 4.7 (released Jun 2026): built-in virtual joystick, gyro/accelerometer, AreaLight3D, new Asset Store, Android export work. HDR not in Compatibility/Android.
- MIT: ProtonScatter, Sky3D (supports Compatibility), Octahedral Impostors (mobile LOD), GLoot (inventory). Pandora (RPG data, updated Apr 2026) license unverified.
- Terrain3D: Android experimental, Compatibility not fully supported -> test before adopting.
- NobodyWho (local LLM GDExtension): **EUPL-1.2 copyleft** -> do NOT ship in the closed commercial game. Use build-time generation instead.
- Rule: MIT/Apache/BSD/CC0 ok; CC-BY needs credit; GPL/AGPL/EUPL/NC avoid.

## Reference games -> CRITTER
- Marvel Rivals: team-up passives, destructible environments, role triad, seasons, cosmetics-only F2P.
- MUA2: pair-unique Fusion attacks; Civil War side choice with side-exclusive characters (= Coalition vs Dominion).
- D&D: SRD 5.2 is CC-BY-4.0 (Apr 2025). Techniques: Session Zero, advantage/disadvantage, rests, DM-as-director.
- Fallout 4: settlements, supply lines, happiness caps, companions as provisioners.
- Skyrim: Word Walls teach shout words (-> Old Road markers teach Knack adaptations), use-based growth, radiant quests, mod ecosystem.

## Revolutionary ideas (tags: G=build now, Y=stretch, R=moonshot)
G Promises-as-game-objects (Zephyr's Promise Law; powers Bond Contracts) | Y Scale Doors (one asset = prop at S0, landscape at S-1)
G Priced foresight / Future-Branch preview (Cigarra) | Y Region simulation + player-readable Consequence Ledger
Y Memory Echoes (Obra Dinn-style deduction on Thoughtstone) | G Species-shaped needs in the Terrarium
Y Build-time AI authoring with lore verification (deterministic at runtime) | R Optional on-device companion chat (license/battery risk)
Y Shared world crisis (aggregate player choices; needs tiny server) | G Moddable data atlas (region recipes/dialogue/canon as validated data)
Y Selective destruction as mechanic | G Session Zero + adaptive Director + advantage/disadvantage | Y Templated fusion for every bonded pair
G Era-midpoint side choice with side-exclusive bonds

## Proposed "Platinum 7" for the overhaul spec
Gate Map + Region Recipe; Bond Contracts + Promises; Micro-Descents; Renown + side choice; Species-shaped needs; Templated Fusion/Team-Ups; Session Zero + Director.
