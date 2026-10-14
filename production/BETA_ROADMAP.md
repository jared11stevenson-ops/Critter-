# CRITTER: Road to the First Beta

Written at v0.29.0 (2026-10-14). Companion to `ROADMAP.md` (brainstorm backlog) and `design/v2/CREATOR_GDD.md` (law). Every task is tagged **[C]** needs the creator, **[L]** Lead can do alone, **[A]** needs new art from the creator's Tripo/ChatGPT pipeline. Effort: **S** < 1 session, **M** 1-2, **L** 3+. Because creator usage is limited, milestones are ordered so that each one ends in a build worth playing and the list can be cut at any line.

## 0. What "first beta" means

A closed beta (20-100 testers on Android) where a stranger can install without Godot, play for an hour, and come back the next day. It is NOT feature-complete; it is the smallest game that honestly delivers the core fantasy in `CREATOR_GDD.md` section 2: **explore -> capture -> fight -> win tournaments -> retire -> grow a habitat jar -> repeat**, with permadeath and the shelf.

### Beta exit gates (all must be true)
| # | Gate | Measured by |
|---|---|---|
| G1 | Installs from an APK on 3+ phone models and boots in < 6 s | tester log + perf report |
| G2 | Zero crashes / save corruption in a 5-hour soak and a kill-the-app-at-every-screen test | scripted + manual |
| G3 | A new player finishes tutorial -> first capture -> first tournament win unaided in under 40 min | 5 observed first-timers |
| G4 | 60 fps p95 on a mid-range phone (Adreno 650 class), 45+ on a low-end one | Perf report on device |
| G5 | Every critter 45-55% overall, no matchup beyond 35/65 at 100 bouts/pair, all three AI levels | tournament matrix |
| G6 | All 8 critters have final models, faces readable, no placeholder art on a critical path | art checklist (section M5) |
| G7 | Day-2 return reason exists (jar tribute + records + a daily nudge) | feature present + tester answer |
| G8 | Crash/feedback reporting works from inside the game | one test report received |
| G9 | Store-ready legal basics: privacy note, asset licenses, content rating answers | checklist |

## 1. Honest starting point (v0.29.0)

**Built and passing 30 test files:** deterministic combat sim, 8 critters x 11 moves with the Move Effect Gate, 3 AI levels, touch layouts A/B, tutorial, shelf (60 jars), expeditions (stalk / direct / provoke), capture and extraction, Blood Bout ladder with per-rung rule modifiers, permadeath, retire and Habitat Jars (real-time, saved), Hall of Records, onboarding tips, named opponents, intro close-ups, music (procedural), 64 SFX, settings (quality, fps, haptics, parry assist), CI that builds a release zip on every push.

**Not true yet (the real gaps):**
1. **There is no installable build.** Releases are a Godot-project zip you import into the Godot mobile editor. No `export_presets.cfg`, no signing, no APK/AAB. This is the single biggest beta blocker.
2. **Almost nothing has been felt on a phone since v0.2.** The only perf/feel data is from 2026-10-11. Music, haptics, intro close-up, all 8 new models in motion, and the last ~25 versions are unverified on device.
3. **Balance is simulated, not played.** Known open pairs: Cigarra v Mollusk ~23%, Scarlith v Bramvex ~25%, Mollusk v Pharilux (timeouts ~45%).
4. **Expedition is one fight** and closing the app mid-expedition has no penalty (save-scum hole).
5. **Habitat is stat-driven**: structures have placeholder names and no art, no observe mode, no lineage view, no succession, no cross-jar links.
6. **Models are rigid cut parts** from Tripo meshes: no skinned animation, seams unchecked, Bramvex icon framing, Cigarra seams. Faces survive but have no expressions.
7. **Content is thin for an hour of play:** a fixed ladder, a few regions that are a list, chapter prose is placeholder, no achievements.
8. **No telemetry, no in-game feedback, no crash reports.**
9. Audio is generated; there is no authored music or final display font (license needed).
10. Tested at 1280x720 mostly; tall phones, notches, foldables and tablets unverified.

## 2. Milestones

Each milestone ends with a tagged build (`v2-0.xx.0`) and a short test script for the creator.

---
### M1 - "It installs" (the blocker; target v0.30)
Goal: any tester taps a link, installs an APK, plays.
| Task | Who | Effort | Done when |
|---|---|---|---|
| M1.1 Add `export_presets.cfg` for Android (arm64-v8a, Compatibility renderer, min SDK 24, target current) | L | S | local headless export produces an APK |
| M1.2 Debug-signed APK in CI (Godot export templates cached, Android SDK/JDK on the runner) attached to every release next to the zip | L | M | release page has `CRITTER2_vX.apk` |
| M1.3 Release keystore + AAB for Play internal testing; keystore stored as a repo secret, backup copy held by the creator | C+L | M | signed AAB uploaded to Play Console internal track |
| M1.4 Package id, app name, adaptive icon (from existing icon art), splash, orientation lock (landscape), immersive mode, safe-area check | L | S | looks right on the S25 |
| M1.5 APK size budget: textures to ETC2/ASTC where it helps, drop unused sources, target <= 150 MB install | L | M | size report in CI |
| M1.6 First on-device smoke: boot, tutorial, shelf, one expedition, save, kill app, relaunch | C | S | creator reports pass/fail per step |

Risk: Android build toolchain eats a session. Mitigation: do M1.1-M1.2 first and ship an APK before anything else.

---
### M2 - "It's felt" (phone truth pass; target v0.31-0.32)
Goal: replace simulated confidence with measured confidence.
| Task | Who | Effort | Done when |
|---|---|---|---|
| M2.1 Creator plays a scripted 30-minute session (tutorial, 2 expeditions, 1 tournament rung, pause/settings, background the app) and fills a 12-line checklist in the debug sheet | C | S | notes landed in `PLAYTEST_NOTES.md` |
| M2.2 In-game debug sheet (hold pause): sliders for walk speed, dodge distance, AI breath, lock turn rate, hold threshold; "send report" copies tuning + last 3 bouts' replay seed to clipboard/share sheet | L | M | creator can retune without a build |
| M2.3 Fix list from M2.1 (budget: top 10 issues) | L | M | each issue closed or ticketed |
| M2.4 Perf pass on 3 device classes (S25, a mid-range, a 3-4 year old phone if available): draw calls (mid-range budget 110), shadow and outline costs per Quality, texture memory, thermal after 20 min | L+C | M | Perf report table in `production/` |
| M2.5 Quality presets that actually protect low-end (Low: no shadows, 2k textures, outlines thinner, particles capped at ~40) | L | M | G4 low-end number met |
| M2.6 Layout sweep: 16:9, 19.5:9, 20:9, tablet, notch cut-outs, left-handed; screenshot grid in CI | L | M | no overflow in any panel |
| M2.7 Audio on device: music vs SFX mix, bout-vs-menu loudness, ducking on hit, silent-mode behaviour | C+L | S | creator signs off mix |

---
### M3 - "It's fair and deep" (combat and balance; target v0.33-0.35)
| Task | Who | Effort | Done when |
|---|---|---|---|
| M3.1 Counterplay audit table (threat kinds x critters); add missing answers as costed skill actions, never passives | L | M | every critter has an answer to every threat kind |
| M3.2 AI style profiles (zoner / brute / trickster) so each kit is handled well at novice/standard/expert; fixes Pharilux stalling and Bramvex swings | L | L | timeouts < 10% for every critter |
| M3.3 Close the open matchups: Cigarra v Mollusk, Scarlith v Bramvex, Mollusk v Pharilux, Nyxaris | L | M | each within 35/65 at 100 bouts |
| M3.4 Full 100-bouts/pair sharded matrix, all three AI levels, committed as `matrix.md` | L | M | G5 met |
| M3.5 Human-vs-AI sanity: creator plays each critter once against standard AI; log perceived power 1-5 | C | S | no critter < 3 or > 4 average |
| M3.6 Difficulty ladder review: opponent levels per rung vs. a median player; rung 1 must be winnable by a first-timer | L+C | M | G3 trial feasible |
| M3.7 Input forgiveness: input buffer, parry window, tell visibility reviewed against phone latency; assist options clearly labelled | L | S | setting list final |
| M3.8 Training/Practice improvements: pick any critter v any critter (decision D2), reset position, move list, frame-data readout toggle | L | M | Practice is a learning tool |
| M3.9 Tournament fairness: rematch seeds, no rule-modifier that hard-counters a role without an answer (Fog, Hazard, Endurance audit) | L | M | rule x critter table clean |

---
### M4 - "The loop has legs" (expedition, tournament, habitat; target v0.36-0.40)
This is where an hour becomes five hours. Pick order is decision D3; recommended order below.
| Task | Who | Effort | Done when |
|---|---|---|---|
| M4.1 **Committed expeditions**: leaving mid-expedition counts as a retreat with a cost; closes the save-scum hole | L | S | test: kill app -> penalty applies once |
| M4.2 **Expedition v2**: 3-5 node route per region with choices (scout / bait / detour), observe and persuade outcomes that change capture odds, visible wild behaviours before the fight, region hazards feeding the arena modifiers | L | L | 3 regions play differently |
| M4.3 **Regions**: 5 regions with ecology, wild roster, material table, music cue, a distinct arena dressing | L+A | L | each region has an identity |
| M4.4 **Tournament v3**: named rivals who remember you (loss/win memory shown in intro), crowd reactions, Champion presentation, defence rounds | L | M | one rival arc end-to-end |
| M4.5 **Habitat v2**: observe mode (watch family: names, events, birthdays), lineage tree, founder succession rule, real structure names from lore, structure art per species (kit-bash from existing models) | L+A | L | jar feels alive |
| M4.6 **Shelf network**: cross-jar passages, jar-to-jar tribute links | L | M | one working link type |
| M4.7 **Economy pass**: scrap/material sinks and sources balanced across 10 hours of simulated play (headless economy sim) | L | M | no dead-end, no runaway |
| M4.8 **Achievements + Records v2** (Hall already exists): 30 achievements, lineage browser, personal bests | L | M | G7 partly |
| M4.9 **Daily return hook**: jar tribute ready, daily rival challenge, local notification (opt-in) | L | M | G7 met |
| M4.10 **Chapter prose** rewrite pass (creator voice replaces placeholder) | C | M | all chapters signed off |

---
### M5 - "It looks like the game" (art lock; target v0.41-0.43)
| Task | Who | Effort | Done when |
|---|---|---|---|
| M5.1 Seam/animation QA of every cut-part model in all poses (walk, strike, heavy, ability, hurt, KO, win) via the turn/pose shooter; fix pivots and hidden seams | L | M | 8 critters pass a pose-sheet review |
| M5.2 Face readability: expression set (idle / hurt / angry / win / lose) swapped by event, blink and eye-dart | L+A | M | faces readable at 1/4 screen size |
| M5.3 Rim light, coloured arena shadows, normal-map quality tiers confirmed on device | L | S | art sign-off |
| M5.4 Arena art: 5 biomes with props and a lookdev pass on backdrops (brown-block ruins in fog is a known defect) | L+A | L | no placeholder arena |
| M5.5 Final UI pass: licensed display font (add to `ASSET_LICENSES`), button states, iconography, transitions | C+L | M | one consistent UI |
| M5.6 VFX audit on device: readability while moving, flashing reduced option honoured everywhere | L | S | no unreadable effect |
| M5.7 Key art + 5 store screenshots + 30 s trailer (screen-captured bouts) | C+L | M | store listing assets ready |
| M5.8 Bramvex icon framing, Cigarra seams, remaining known art defects | L | S | list cleared |

---
### M6 - "It's safe to hand to strangers" (robustness; target v0.44)
| Task | Who | Effort | Done when |
|---|---|---|---|
| M6.1 Save robustness: versioned schema, migrations from every released version, atomic write + backup, corrupted-file recovery UI | L | M | G2 save part |
| M6.2 Kill-test harness: scripted app kill at each screen and mid-write; assert state valid | L | M | 0 failures in 200 runs |
| M6.3 Soak test: 5 h unattended AI-vs-AI plus UI-driven loop; memory growth chart | L | M | no leak, no hitch growth |
| M6.4 Crash/error capture: error log ring buffer + "Send report" (email/share) with version, device, last events | L | M | G8 met |
| M6.5 Optional anonymous telemetry (opt-in): session length, rung reached, deaths, quit points, bout durations | L+C | M | funnel visible |
| M6.6 Time-cheat resilience for real-time jars (clock changes, long absences) | L | S | tests pass |
| M6.7 Accessibility: text scale, colour-blind-safe tells (shape + colour), reduced flashing, one-handed layout check | L | M | checklist done |
| M6.8 Localisation scaffold (strings out of code) even if only English ships | L | M | no hard-coded UI text |
| M6.9 Legal: privacy note, third-party licences screen, content-rating questionnaire (violence, permadeath), asset provenance of Tripo models | C | S | G9 met |

---
### M7 - "Beta" (target v0.50.0-beta1)
| Task | Who | Effort | Done when |
|---|---|---|---|
| M7.1 Feature freeze; only fixes from here | L | - | branch `beta` cut |
| M7.2 Internal test (creator + 3 friends) 3 days; triage into P0/P1/P2 | C | S | P0 = 0 |
| M7.3 First-timer observation x5 (G3) | C | M | median < 40 min to first tournament win |
| M7.4 Play Console closed track + tester list + Discord/Telegram feedback channel + FAQ | C | S | 20 invited |
| M7.5 Beta 1 build, release notes, known-issues list | L | S | live |
| M7.6 Weekly beta cadence: triage, fix top 5, ship; track D1/D7 return, crash-free %, funnel | L | ongoing | dashboard in `production/` |

## 3. Critical path and cut line

`M1 (APK) -> M2 (phone truth) -> M3 (fair) -> M4.1-4.2 (expedition) -> M5.1-5.2 (art lock) -> M6.1-6.4 (robust) -> M7`

If time or usage runs short, the **minimum viable beta** is: M1 + M2 + M3.1-3.4 + M4.1 + M4.9 + M5.1 + M6.1-6.4 + M6.9 + M7. Everything else (rivals, shelf network, region art, telemetry, achievements) can ship in beta 2-4.

## 4. Suggested release train

| Version | Contents |
|---|---|
| v0.30 | M1: first installable APK |
| v0.31 | M2.1-2.3: device feel fixes, debug sheet |
| v0.32 | M2.4-2.7: perf presets, layouts, audio |
| v0.33-0.35 | M3: counterplay, AI styles, matrix, Practice |
| v0.36-0.37 | M4.1-4.3: committed expeditions, expedition v2, regions |
| v0.38-0.40 | M4.4-4.9: rivals, habitat v2, economy, achievements, daily hook |
| v0.41-0.43 | M5: art lock |
| v0.44 | M6: robustness, reporting, legal |
| v0.50.0-beta1 | M7 |

## 5. Decisions needed from the creator (blocking)

1. **Platforms for beta:** Android only (recommended), or iOS too (needs Apple dev account, Mac build, TestFlight - adds a milestone)?
2. **Distribution:** Play closed testing (recommended; needs a Play developer account, one-time fee) vs. direct APK links only.
3. **Order of M4 work** (habitat v2 vs expeditions vs tournaments). Recommended: expeditions -> tournaments -> habitat.
4. Default lock state in bouts (locked now); Practice: any critter v any critter, or only your own jars (still open from the old list).
5. **Monetisation stance for beta:** none (recommended), with the economy built so nothing in it implies power-for-money.
6. **Telemetry:** opt-in anonymous analytics yes/no.
7. **Name and package id** (`com.<you>.critter`), final title, age rating target.
8. **Art scope for beta:** how many region backdrops and structure sets are required vs. nice-to-have; who makes them (Tripo pipeline per asset, or kit-bash).
9. **Music:** keep procedural for beta, or commission/license authored tracks?
10. **Chapter prose:** will the creator write it, or should Lead draft for approval?

## 6. Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Android export toolchain slips | M | High | do M1 first; produce debug APK before Play work |
| Unfelt features feel bad on device (haptics, close-up, music) | H | M | M2 is early and cheap; debug sheet lets creator retune |
| Mid-range phones can't hold 60 fps with textured models + outlines | M | High | M2.4-2.5 early; Low preset cuts shadows/outline/texture |
| Balance by AI sim diverges from human play | H | M | M3.5 human sanity and telemetry after launch |
| Real-time habitat exploited or confusing | M | M | M6.6, clear UI copy, cap catch-up (48 days already) |
| Save migration bugs lose a permadeath career | L | Very high | M6.1-6.2 before any external tester |
| Art scope creep (29-point polish list) | H | M | art lock criteria in M5 only; rest to post-beta backlog |
| Weekly usage runs out mid-milestone | H | M | each milestone ends in a shippable build; cut line in section 3 |
| Tripo asset licensing / provenance questions | L | High | record generation source and plan terms in `ASSET_LICENSES` before store submit |

## 7. Working agreements

- Every release: tests green (30+ files), size lint, matrix delta noted, release notes with what was **not** verified.
- Laws never bend for schedule: two fight kinds only, no hidden role multipliers, counters are skill answers, stars display-only, permadeath honest, ~50% balance target.
- New scope needs an entry in `PREFLIGHT.md` first.
- Playtest findings go to `PLAYTEST_NOTES.md` with date, device and version.
