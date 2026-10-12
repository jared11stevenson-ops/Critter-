# CRITTER roadmap (brainstorm after v0.10.0)

## Where we are
Working loop: tutorial (Aruun) -> shelf (60 jars) -> expeditions (stalk/direct/provoke) -> capture and extraction -> Blood Bout tournaments to Champion -> retire -> Habitat Jars (family, structures, tribute). 8 critters (Pharilux added), 3 stars of skill, counterplay as skill (parry cleanse, tenacity), free lock-on, space-to-move AI. 29 tests green, balance 42-57% overall.

## Lacking (honest)
1. **No real playtest data.** Every feel claim (spacing, lock, riposte, ring-outs) is simulated, not felt.
2. **Pairwise balance is noisy** (30 bouts/pair) and AI skill levels treat some kits unevenly (Bramvex, Pharilux).
3. **Counterplay gaps**: not every critter has a skill answer to each threat kind (status, zones, grabs, escape, burst).
4. **Models are placeholders**; Pharilux in particular is low poly. Creator's Blender models pending.
5. **Habitat is a spreadsheet with pictures**: family and buildings are drawn shapes; no observation, no names/stories, no jar-to-jar links.
6. **Expedition is one fight.** No exploration, no persuasion, regions are a list.
7. **Tournaments are a fixed ladder**: no rule modifiers, no rivals, no spectators/crowd, no audience reward.
8. **Music missing**, SFX generated, VFX good but untested on low-end phones.
9. **Onboarding**: tips exist, but jar-tap, LOCK, stars, approaches are not taught.
10. **Retention**: no daily/return hook except jar tribute; no achievements/records screen.

## Next (ordered)
**A. Feel pass (2 sessions)** make the game tunable from playtest: in-game debug sheet (hold pause) with sliders for walk speed, dodge distance, AI breath, lock turn rate; record 3 bouts to a replay file the creator can send back; fix what the phone playtest finds.
**B. Counterplay audit** one table: threat kinds x critters; add the missing answers as costed skill actions, not passives. Re-run matrix at 100/pair after.
**C. AI per-skill-level quality** adapt AI "styles" (zoner, brute, trickster) so every kit is handled well at novice/standard/expert (fixes Bramvex/Pharilux swings).
**D. Habitat v2** observe mode (watch the family: names, small events, birthdays), generations and lineage tree, founder monarch crown and succession rule, cross-jar passage (shelf network), real structure art per species.
**E. Expedition v2** exploration nodes (path choices), observe/persuade outcomes that change capture odds, wild critter behaviours visible before the fight, region hazards as arena modifiers.
**F. Tournament v2** rule modifiers (Sudden Death, Endurance, Hazard ring, Ring-out rules), named rivals who remember you, crowd reactions, Champion Tournament presentation, defend-the-title loop.
**G. Onboarding and clarity** teach LOCK, jar-tap, stars, approaches in the shelf and first expeditions; a "move list" screen per critter.
**H. Presentation** music hooks, Pharilux/others model upgrade when Blender models arrive, camera polish in FREE mode, low-end performance budget run.
**I. Records and progression** achievements, hall of champions, lineage and wall of the fallen browser, daily jar tribute.

## Principles (creator law, restated)
Two fights only (Blood Bout, Practice). Roles are styles; counters are skill answers, never hidden multipliers. Stars never mean power. Every critter equally strong in different ways. Pre-Flight list before new scope.

## Decisions needed from the creator
1. Default lock state in a bout: locked (now) or free?
2. Should Practice allow any critter vs any critter, or only your own jars?
3. Priority order of D (habitat), E (expeditions), F (tournaments) after the feel pass.
