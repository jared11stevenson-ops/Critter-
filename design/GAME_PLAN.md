# CRITTER — Game Plan (Lead, 2026-10-05)

Current build: **v0.13.0**, a playable Red Reaches slice with the Ledger, rivals, bonds, NPCs and 3D characters.
Creator priorities right now: world-building the lore describes, character-model fidelity, smooth performance.
Paused by the creator: lore, music, quests, dialogue.

## Where we really are
| Area | State | Honest grade |
|---|---|---|
| Systems (Ledger, Rivals, Bonds, Promises, Session Zero, Gate Map, Gear) | built, 84 tests | solid |
| Performance | draw calls 150 (budget 150), primitives 328k (too high), measured only on a software renderer | unknown on phones |
| Characters | Aruun about 65–70%, Cigarra about 50–55% of sheets; NPCs are mannequin-grade | main quality gap |
| World | Red Reaches has settlements, weather and spokes; art is kit-bashed placeholder quality | second quality gap |
| Content data | 6 regions, 36 quests, 66 gear, 12 NPCs (data complete, paused) | ahead of the art |
| Infrastructure | no off-box backup, container restarts, usage limits | risk |

## Phases (each ends with a zip you can test)
**Phase A — Look (now to v0.16): make it look like the references.**
- A1 Character artist: Aruun to 90%, then Cigarra to 85%, using a studio pipeline (sculpt, bake, hand-paint, skin). Exit: side-by-side boards you approve.
- A2 Environment artist: Red Reaches and hub art pass (kits, terrain shader, atmosphere); polygons at or below 220k. Exit: five hero vistas you approve.
- A3 Cast pipeline: roll the artist's method to the 10 hub NPCs and 12 Red Reaches NPCs.

**Phase B — Feel (v0.17 to v0.20): smooth and satisfying.**
- Real-phone telemetry (in-game performance overlay writing a log), then fix what your phone shows.
- Combat feel pass: animation timing, hit-stop, camera, audio hooks (your music slots stay empty until you send tracks).
- Hub on the new NPC code, NPC collision and avoidance.

**Phase C — Breadth (v0.21 to v0.30): a second and third world.**
- Canopy Fold, Lumen Depths (then the rest) built from the region recipe files with their own palettes, shape language, props and creatures. Each world must feel unique, not re-skinned.
- Gate Map becomes the real world map.

**Phase D — Depth (v0.31 to v0.60): the systems around the world.**
- Squad of three, Knack Wheel, Fusion/Team-Up, Expeditions, base needs and metamorphosis, Era structure.
- Resumes the paused work: quests, dialogue, lore rewrite, music.

**Phase E — Ship (v0.61 to v1.0).**
- Balance, onboarding, accessibility, save safety, store build, IP review of the Rivals system, credits and licenses.

## Standing workstreams
- **Quality gates for every merge:** `tools/validate.sh`, full playthrough with zero script errors, draw-call peak at or below 150, zip under 30 MiB.
- **Agents:** hired Character Artist (Aruun, Cigarra, then cast), hired Environment Artist (Red Reaches, hub, then new worlds), Agent 2 (gameplay and world logic, performance), Agent 3 (content data, on hold). Weekly scorecard update.
- **Process:** small commits every 10 minutes, Lead merges and resolves conflicts, files have owners.

## What blocks us (needs the creator)
1. Install the Claude GitHub App on the repo (backup, plus live sync for your Godot editor).
2. Phone playtest notes after each zip (what lags, what looks wrong).
3. Decisions: squad size 2 or 3, server features yes or no, which worlds after the Red Reaches.
4. Whenever ready: lore rewrite and music tracks.

## Risks and mitigations
- **Art ceiling:** scripted modeling plateaus. Mitigation: the Character Artist surveys image-to-3D and sculpt tooling and reports; fall back to a human artist for hero assets if needed.
- **Mobile performance unknown:** mitigation is the telemetry overlay and the polygon cut.
- **Lost work:** mitigation is GitHub, plus frequent commits meanwhile.
- **Scope creep:** the 25-system master plan stays in Phase D; nothing new enters before Phase A exit.

## Standing order (creator, 2026-10-06)
Sequence: (1) ARUUN until he passes every fidelity gate (design/FIDELITY_PROTOCOL.md, final >= 92/100 and Silhouette/Proportions/Head-Neck-Horns each >= 90%), (2) then CIGARRA through the same protocol, (3) only then return to the game (integration, zips, world, gameplay). Everything else stays paused until then.
