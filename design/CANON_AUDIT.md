# CRITTER — Canon Fidelity Audit (Agent 3, v0.7.0 build, 2026-10-03)

Scope: the in-game build vs. the lore bible v12 (`design/lore_bible_v12.txt`), `game/canon/canon.json` and the approved model
sheets in `tools/source_art/`. This is a partial pass: the run was cut short for the playable build. Every row says
whether I checked it in engine or only in data.

**Method.** The scenes were captured with `tools/shot.sh` on Godot 4.7.2 Compatibility (llvmpipe, 1280x720):
- title: `boot.tscn`
- hub: `hub.tscn` + `ui_tour_hub.json`
- Red Reaches critical path: `rr_critical_path.json`, 8 of 11 beats captured before the timeout
- boss: `rr_boss.json`, phases 1-3 and the choice
- habitat: `habitat_visual_qa.tscn`

I also read all 12 character sheets, checked every dialogue `who/expr` pair against the portrait files, and checked the
codex text against the bible. The evidence shots are in `design/model_sheets/_qa/`.

Severity: **H** = visibly wrong or contradicts canon; **M** = hurts readability or fidelity; **L** = minor or cosmetic.

## 1. Canon checks that passed
| Check | Result |
|---|---|
| Heights: sheet vs `canon.json` vs billboard `meta.json` | All match. Aruun 240 cm, Cigarra 165 cm, Nerit 175 cm, Mollusk 220 cm, Zephyr 165 cm, Nyxaris 200 cm, Pharilux 260 cm, **Scarlith 12 cm**, **Solmara 5.5 m**, Mara 170 cm, Dexter 185 cm. The billboard maps texture height to `height_m`. Bramvex 2.3 m: see A-6. |
| Relative scale in engine | Aruun:Cigarra is about 1.35 on screen vs 1.45 canon, which perspective explains. Solmara:Pharilux in the hub is about 2.1 vs 2.1 canon. Scarlith stands on the Common Table at 12 cm, matching the dialogue "Down here… On the table." |
| Designations in the codex | All 10 match the bible: BRU-004, PSI-017, LUX-031, CHR-001, AER-009, CRYO-022, UNKNOWN (Pharilux), MYC-013, TID-001, MIL-006. |
| Names and titles | Codex titles, "Dr. Mara Venn" and "Dexter Mane" all match the bible and sheets. The AUGUR-7 Deepcore Rig matches `canon.json` and the GDD. |
| Portrait coverage | All 43 `(who, expr)` pairs used in `game/narrative/dialogue/*.json` resolve to an existing `game/art/portraits/<id>/<expr>.png`. None are missing. |
| Visual identity | Every billboard is cut from the approved sheet. Nothing is redrawn, and no design deviates from the bible's "immutable" notes (Cigarra crown, Aruun giraffe-beetle with Morrow, Nerit glow-worm, Mollusk snail, Pharilux lantern mantis, Scarlith velvet mite with cheese, Solmara sea spider, Bramvex stick insect, Nyxaris, Zephyr). |

## 2. Findings
### A. In Agent 3 files (characters, portraits, icons, pipeline)
| # | Sev | Finding | Status |
|---|---|---|---|
| A-1 | H | Billboards were soft and JPEG-noisy, and some were badly under-resolved for their screen size: **Solmara 176-186 px tall for a 5.5 m character**, Bramvex 229-238 px, Mara ~324 px, Dexter back 234 px, Scarlith side/back 156-173 px. Parchment fringe showed at the edges. | **Fixed for 8 of 12** (aruun, cigarra, bramvex, solmara, dexter, mara, scarlith, zephyr). Re-cut from Real-ESRGAN x4 sheets with sub-pixel edge re-keying, decontaminated and bled edges, and premultiplied Lanczos downsampling, at one height per character (512 px; Solmara 576; Scarlith 384). Same framing, filenames and meta schema (aspect change < 0.15%). |
| A-2 | M | **Mollusk, Nerit, Nyxaris and Pharilux still use the old x1 cuts** (softer, with some fringe). | Open. The pipeline is ready (`hd_sprites.py`); it needs the x4 sheets. Mollusk's x4 regions are done (scratch only, not committed). |
| A-3 | M | Portraits and ability icons are still 60-140 px sheet crops upscaled to 256 px, so they look soft. | Open. `cut_portraits.py --x4` is implemented but **not run**. The current portraits are unchanged and complete. |
| A-4 | M | Cigarra front: the collar/hood was clipped by a straight exclusion edge. | **Fixed** (`sprite_boxes.json`). |
| A-5 | M | Dexter front/side: the coat's left edge was cut straight at the panel box, and the hair was flat-clipped. | **Fixed** (box widened, bio text excluded). The right coat edge stays straight because the lab-coat figure overlaps it on the sheet (unrecoverable). |
| A-6 | L | Bramvex's sheet has **no printed height**. The 2.3 m figure is inferred from the scale panel. | Creator should confirm. |
| A-7 | M | **Dexter has no side view on the sheet**, so `side.png` is a copy of the 3/4 `front.png`. Mara's and Aruun's "front" views are 3/4 poses on their sheets. | Needs creator art (an orthographic side/front) before any 3D work. |
| A-8 | L | Zephyr side/back carried stray wing fragments from the neighbouring turnaround view. Sheet ground lines appeared under some feet. | **Fixed** (generic fragment and ground-line cleanup). |
| A-9 | L | Bramvex side: a pale area between the legs is the translucent wing membrane as painted, not background. | Kept as-is (faithful to the sheet). |
| A-10 | L | HD cuts are about 4% darker on average than the old cuts, because the x4 pass removes JPEG haze and parchment fringe. | Accepted. Closer to the sheet. |

### B. Owned by other agents or the Lead (not changed by me)
| # | Sev | Finding | Evidence | Suggested owner / fix |
|---|---|---|---|---|
| B-1 | M | **Hub readability.** At the hub camera the cast is about 40-70 px tall, and the world-space name plates cover several characters entirely (Mollusk, Scarlith, Zephyr). Scarlith (12 cm, correct canon) is invisible under his plate. | `_qa/audit_hub_common.jpg` | Agent 2 (hub UI/camera): raise plates above the head and shrink them, or show them on proximity/tap. Optionally add a zoom-to-NPC on tap. |
| B-2 | M | **Boss arena camera.** In phases 1-3 the party is about 20-30 px tall, so the character art is unreadable. | `_qa/audit_boss_p1.jpg` | Agent 2 (camera): frame the party plus the rig, or tighten the camera between drill telegraphs. |
| B-3 | M | **Boss "Thoughtstone shards"** render as flat, untextured light-blue slabs. They read as ice or glass and sit outside the Red Reaches / sheet palette. The bible does not fix Thoughtstone's colour, but nothing in canon is pale blue. | `_qa/audit_boss_p3.jpg` | Agent 1/2: give them a stone material in the Reaches palette, or the reddish crystalline look of Morrow's inlays. |
| B-4 | L-M | **Unused expression sets.** `canon.json` lists no `expressions` for Scarlith or Solmara, although both sheets have 5 expression studies and the portraits exist (scarlith: neutral/curious/calculating/aggressive/satisfied; solmara: calm/aggressive/defensive/curious/ritual). As a result all their lines use `default`. Nerit has expressions in canon, but all 4 of his lines also use `default`. | `hub_npc_*.json` | Lead (canon.json) and the narrative owner. Suggestions: Nerit "…afraid to measure absence." → `unsettling`; Scarlith "Excellent customers. Terrible precedent." → `calculating`; Solmara "…Is that a threat display?" → `curious`. |
| B-5 | L | **Expression/tone mismatches in dialogue.** | — | Narrative owner. Suggested changes: Aruun `aggressive` on "It'll stand a season. Maybe two." and "Plate beetles don't charge. They graze." → `focused`. Cigarra `shocked` on "Big beam… Stand in the ones without holes." → `focused`. Cigarra `focused` on "Across. Everyone's across. You can let go." → `happy`. Mara `soft` on "Bringing you up. Brace for the Tilt." → `focused`. Mara `curious` on "…I'm framing page twelve." → `soft` (she has no amused portrait). |
| B-6 | L | **Codex knack strings are truncated** vs canon. Cigarra "Probability Perception" (canon adds "/ Psychic Interference"). Bramvex "Camouflage / Sensory Adaptation" (canon adds "/ Tactical Terrain Use"). Zephyr "Motion / Pollination" (canon: "Motion / Atmospheric Disturbance / Pollination"). | `game/canon/codex.json` | codex.json owner. |
| B-7 | — | **Title screen not audited.** The QA capture of `boot.tscn` stayed on a blank dark frame at 4 s and 7 s, with 1 draw call. This is probably the QA boot path, not a confirmed bug. | `audit_title.png` (blank, not committed) | Agent 2: confirm the title shows in a normal launch. |
| B-8 | L | Bramvex and Nyxaris have a single portrait. Their sheets have no expression panel, consistent with canon.json. | — | Information only. A future art request if they get more dialogue. |

## 3. Not yet audited (out of time)
- Red Reaches beats after "Cross the Ochre Span": the capture timed out at 8 of 11 shots.
- Creature, enemy and world-prop canon vs the bible's region text (Red Reaches flora/fauna).
- Habitat: captured, but only the Dust Grazer (Agent 1 creature) appears. No cast characters to check.
- Portrait-to-tone pass on the remaining ~150 lines of the most frequent pairs (aruun/calm, mara/focused, mara/neutral): only sampled.
