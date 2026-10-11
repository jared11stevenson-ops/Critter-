# CRITTER — How we make the game (Lead, 2026-10-11)

## 1. What went wrong in game one, and the rule that prevents it
| # | Mistake | Cost | Rule now |
|---|---|---|---|
| 1 | Built 25 systems before one thing felt good | A confusing, unfun first minute | **Feel gate:** nothing else starts until 5 minutes of the core duel is fun on a phone |
| 2 | Loop not stated in a sentence | Confusing HUD and hub | **One-sentence loop** (GDD 3) and a **5-minute stranger test** each milestone |
| 3 | Art needed a pipeline that could not hit reference fidelity | Months on one model | **Design to the tools:** rigid-part toon characters we can build and animate in code; outsourced art optional, later |
| 4 | Parallel agents edited the same files | "Last pass ruined a lot" | **Folder ownership** (INTERFACES.md), contracts, one owner per folder |
| 5 | No automated regression gate | Breakage found by the creator | **CI smoke bot** plus golden screenshots plus unit tests on every push |
| 6 | Tuned on a software renderer, shipped by chat | Wrong numbers, 30 MiB cap | **Real-phone telemetry** and **GitHub Releases** |
| 7 | Monolithic scene scripts (thousands of lines) | Fragile changes | **File size lint** (soft 400 lines, hard 700) and components |
| 8 | Context lost at limits and restarts | Rework | **Decision log, handoffs, tickets in files**, small tasks, commits every 10 minutes |
| 9 | Merged without evidence | Silent regressions | **Definition of Done** requires numbers and screenshots |
| 10 | Broad "do everything" briefs | Sloppy output | **Tickets with acceptance criteria**; agents deliver one thing at a time |

## 2. The studio
| Role | Who | Responsibility |
|---|---|---|
| Game Director | Lead | Vision, plan, gates, integration, creator comms |
| Combat Engineer | agent | CombatSim, moves, AI, balance tournament |
| Character Artist (Technical) | agent | Critter rigs, shaders, expressions, turnarounds, animation poses |
| Arena/Scene Engineer | agent | Arenas, camera, hit-stop, bout wiring |
| UI/UX Engineer | agent | HUD, touch controls, Rack/jars, story panels |
| Platform Engineer | agent | Core services, save, perf, input, build/CI |
| QA Engineer | agent | Smoke bot, golden screenshots, playtest scripts, bug reports |
| Producer | Lead | Backlog, risks, release notes |

## 3. Cadence: one build per sprint
1. **Plan:** tickets in `production/BACKLOG.md` with acceptance criteria and owners.
2. **Build:** each agent works in their own folder in their own worktree/branch, commits every 10 minutes.
3. **Integrate:** the Lead merges branches only if all gates pass.
4. **QA:** smoke bot plus balance tournament plus perf report.
5. **Release:** GitHub Release zip with a one-page change log and "what to test" list.
6. **Retro:** `production/RETRO.md` (what to keep, fix, stop).

## 4. Definition of Done (every ticket)
- Acceptance criteria met and demonstrated (screenshot, number, or test output).
- Unit/system tests added or updated and green.
- No new script errors in the smoke run; no performance regression beyond budget.
- Docs/data files updated; interface contract unchanged (or Lead-approved).
- Reviewed by the Lead against the gate list below.

## 5. Gates
1. **Automated:** all tests green; smoke bot clean; balance matrix within targets (once combat exists).
2. **Perf:** draw calls, tris, script ms, hitches under budget (Part 6).
3. **Feel (combat/controls):** measured input latency and a phone playtest note.
4. **Clarity (UI/loop):** the stranger test.
5. **Look:** silhouette, color, pop and style tests; creator sign-off for hero art.
6. **Rollback:** every release tagged; one-command rollback documented.

## 6. Budgets
| Metric | Flagship (60 fps) | Mid-range (30 fps) |
|---|---|---|
| Frame time | 16.6 ms | 33.3 ms |
| Draw calls in a bout | <= 150 | <= 110 |
| Triangles in a bout | <= 120k | <= 80k |
| Script time | <= 4 ms | <= 6 ms |
| Hitch >50 ms | none in a bout | none in a bout |
| Cold start to input | <= 5 s | <= 8 s |
| Touch-to-pixel latency | < 80 ms | < 100 ms |

## 7. Pre-Flight rule (creator's standing order)
**Before the creator adds a change or new feature, the Lead first presents the Pre-Flight List: the improvements to existing work that should be completed before more is added**
(bugs, performance, feel, clarity, balance, tech debt, missing tests), ranked, with effort and impact. Only then do we add the new request, unless the creator says otherwise.
The current list lives in `production/PREFLIGHT.md` and is updated every sprint.

## 8. Communication
- The creator receives: one summary per release (what changed, how to test, known issues), screenshots, numbers, and the Pre-Flight List.
- Open decisions are collected in `design/v2/DECISIONS.md` with a recommended default so work never blocks.

## 9. The Laws gate (creator, 2026-10-11)
design/v2/CREATOR_GDD.md section 14 is law. Gate 0 for every ticket and merge: "Does this contradict a Core Design Law?" If yes, it is rejected or escalated to the creator as a design revision request. Tickets must list the laws they touch.
