# Development landscape: what others do, what we do, where the gaps are (development process only)

Scope: how games are BUILT in 2026, not what our game is. Compiled 2026-10-18 from a research sweep (links at the end). Evidence quality: many sources are vendor blogs and aggregators; claims are marked (solid) when backed by a paper, official post or survey, (soft) when from marketing blogs. "Us today" is checked against this repo.

## A. What others do that we do not (yet)
| # | Practice | Evidence | Us today | Gap and action | Cost |
|---|---|---|---|---|---|
| 1 | CI that builds the real target (APK/AAB), nightly runs, device-cloud or real-device checks | (soft) testing-trend posts; standard industry practice | CI runs 31 test files, a smoke bout, a file-size lint and zips a Godot project; NO Android export, NO device test | Add Android export + signed APK in CI and a nightly job (BETA_ROADMAP M1.1-1.2); real-device perf run by the creator's phone at milestones | M |
| 2 | Performance budgets enforced automatically (frame time, memory, draw calls) | (soft) job listings and testing guides | Draw calls/tris are tested statically per critter; runtime perf only via a manual Perf report | Add a headless render budget gate (draw calls, tris, shader compile count) to CI and keep per-version history in `v2/tools/out/perf.json` | S |
| 3 | Visual regression testing (screenshot diffs) | (solid) VideoGameQA-Bench covers visual unit/regression tests | Screenshots are taken by hand for review only | Golden-image diffs for UI screens and a pose sheet per critter; flag changes above a threshold | M |
| 4 | VLM-assisted QA triage | (solid, 2026 papers): off-the-shelf VLMs reach ~0.5 precision / 0.72 accuracy on gameplay video; best used as high-recall FILTERS before human or rule checks | none | Do not rely on VLMs alone: pair with our deterministic checks (animation lint, E9) and use a VLM only to shortlist frames for review | M |
| 5 | Telemetry, crash reporting, D1/D7/D30 gates before launch | (soft) retention benchmark posts; median D1 about 22%, D7 under 4% across all games, marketed titles far higher; iOS above Android | none (no telemetry, no crash reports) | Opt-in anonymous telemetry + in-game error report; pre-register go/no-go gates (e.g. D1 >= 30%, D7 >= 10% in the closed beta) BEFORE seeing data | M |
| 6 | Learned/agent-based balance and playtesting | (solid) EA research agents found imbalance in a shipped game; RL does not transfer cheaply and needs tuning | Scripted AI matrix (sharded, 100 bouts/pair) | Plan E2/E3: learned agents as the balance oracle at skill ceiling; keep human sanity checks (research warns heuristics-only balance misleads) | L |
| 7 | Rollback/deterministic netcode as the standard for fighting games | (soft) several explainers; requires deterministic sim | The sim is deterministic but no online play | No action for beta; keep the sim rollback-ready (save/load state API, no hidden globals). Add a "state snapshot + resim equals original" test | S |
| 8 | Platform AI-disclosure compliance | (solid-ish) Steam rewrote its rule in Jan 2026: shipped AI-generated content must be disclosed, dev-only tools exempt; Apple/Google sources conflict | The licence ledger was DELETED in my v1 cleanup | Restored and rewritten: `design/v2/ASSET_LICENSES.md` with TO VERIFY items for the creator | S (done) |
| 9 | Engine-agent bridges (Unity official MCP beta, community Godot MCP) for editor automation | (soft) vendor/directory pages | We drive Godot by CLI, headless, scripts and screenshots (equivalent for our needs) | WATCH only: adopt godot-mcp only if editor-side tasks (scene editing, profiler) become blocking | S |
| 10 | Wishlist/community pipeline started months before launch (Steam: page ~6 months ahead, demo ~3 months before a fest; pre-fest wishlists strongly predict results) | (soft) marketing blogs, one 182-dev survey | none | Not our job now, but note the lead times: the beta build is also the first public demo; plan a devlog + capsule art + Discord alongside M7 | M |
| 11 | Learned motion matching in AAA animation (Ubisoft La Forge paper, 2020; Unity asset) | (solid) paper | hand-authored procedural poses | Motion matching needs mocap libraries and humanoid data: poor fit for our creatures. IGNORE for now; reconsider only for humanoid-ish critters if E7 yields usable data | - |

## B. What others do NOT do (or do badly) that we should
| # | Opportunity | Why it is open | Action | Cost |
|---|---|---|---|---|
| 1 | **Hybrid automated QA: deterministic metrics first, VLM only as a filter** | Research shows VLM-only QA is ~50% precise; studios mostly still use manual QA for animation quality | Animation lint (E9) + golden images + VLM shortlist; makes autonomous workers reliable without a human eye | M |
| 2 | **Provenance ledger generated automatically in CI** (hash, generator, prompt, date, licence per asset) | Compliance is ad hoc; players punish AI content that looks uncared for ("lazy", "soulless", extra fingers) and platforms now require disclosure | `tools/provenance/check.py`: fail CI if a shipped asset has no ledger row; produce the store disclosure text | S |
| 3 | **Human-in-the-loop acceptance criteria for every AI-made asset** | A 2025 synthesis found efficiency gains in prototyping are often erased at integration unless acceptance criteria are engineered | Our pipeline already gates models on detail preservation and silhouette tests; add per-asset acceptance checklists (face readable at quarter size, no seams in 6 poses) | S |
| 4 | **Budget-capped autonomous workers on a rules file** (production/AUTONOMY.md) | Most AI use is ad hoc chat or IDE assist (about a third of developers use gen-AI at work; mostly non-creative tasks) | Keep refining: run counters, one step per run, tests as gates, honest logs; publish the method as a devlog (reputation advantage, not just process) | S |
| 5 | **Determinism as infrastructure**: golden replays that must hash identically across versions and platforms | Few small teams verify cross-platform determinism; it unlocks rollback, async ghosts and reliable balance data | Golden-replay hash test in CI (x86 now; arm64 via the creator's phone at milestones) | S |
| 6 | **Pre-registered launch gates** (decide the pass/fail numbers before the data exists) | Soft-launch guides recommend it; many teams move the bar afterwards | Write the gates into BETA_ROADMAP now (see A5) | S |
| 7 | **Measured creator-time budget as a first-class constraint** | Almost every pipeline assumes unlimited human review time | Every step has a usage cost label and a stop rule; reviews are batched into one contact sheet per critter | S |
| 8 | **Honesty reports with every build** ("what was NOT verified") | Postmortems routinely show features shipped unverified | Already our habit; make it a required section of every release note and AUTONOMY log line | S |

## C. Recommended order (development only)
1. Provenance ledger + CI check (B2, A8): small, protects every later store submission.
2. Golden-replay determinism test and sim snapshot/resim test (B5, A7): enables learned agents, ghosts and rollback.
3. Animation lint (B1 / E9) and render-budget gate (A2): lets autonomous workers iterate safely.
4. Android export in CI (A1): the real beta blocker.
5. Pre-registered beta gates and opt-in telemetry design (A5, B6).
6. Golden-image diffs + VLM shortlist (A3, A4).
7. Learned balance oracle (A6) once the gym exists.

## D. Things I could not verify
Apple's and Google's current AI-content rules (sources conflict); exact Steam Next Fest dates (sources disagree); whether UniRig's skinning stage is publicly released; any 2026 studio postmortem on human-in-the-loop AI QA; real numbers for rollback on mobile; the quality of modl.ai/EA SEED tooling beyond marketing pages.

## Sources
- Testing and CI trends: [Top Game Testing Trends 2026](https://snoopgame.com/blog/top-game-testing-trends-to-watch-in-2026/), [automated testing for indie games](https://www.wayline.io/blog/automated-testing-indie-game-development), [DevOps continuous testing for games](https://www.kovair.com/blogs/devops-continuous-testing-techniques-for-game-developers/)
- AI agents and editors: [Unity MCP overview](https://dev.to/pneumetron/unity-mcp-bridging-ai-assistants-with-unity-for-automated-game-development-297l), [Godot MCP](https://enterprisedna.co/directories/mcp/coding-solo-godot-mcp), [Unity vs Godot with AI tools](https://ziva.sh/blogs/unity-vs-godot-2026-ai)
- Animation ML: [Learned Motion Matching (Ubisoft La Forge)](https://www.ubisoft.com/en-us/studio/laforge/news/3NWqwcMU9lMfumgfPAEfka/learned-motion-matching), [paper](https://www.theorangeduck.com/media/uploads/other_stuff/Learned_Motion_Matching.pdf)
- Balance agents: [Assessing video game balance using autonomous agents](https://arxiv.org/pdf/2304.08699), [Exploring gameplay with AI agents (EA)](https://ojs.aaai.org/index.php/AIIDE/article/view/13034), [Winning isn't everything (EA)](https://ar5iv.arxiv.org/html/1903.10545)
- VLM QA: [VideoGameQA-Bench](https://arxiv.org/html/2505.15952v1), [VLM visual bug detection in gameplay video (2026)](https://arxiv.org/abs/2603.22706), [VLM clipping detection (Sony, CoG 2026)](https://www.alphaxiv.org/abs/2607.25921)
- Netcode: [Rollback netcode explained](https://crux.supercraft.host/blog/rollback-netcode-explained/), [how to implement rollback for fighting games](https://bugnet.io/blog/how-to-implement-rollback-netcode-for-fighting-games)
- Policy: [AI game assets in 2026: copyright, Steam disclosure, platform compliance](https://blog.promise.legal/ai-game-assets-copyright-steam-disclosure-2026/), [Steam updates AI disclosure policy](https://tbreak.com/steam-ai-disclosure-policy-update-developers/)
- Launch and retention: [soft launch go/no-go gate](https://getbruin.com/use-cases/mobile-gaming/soft-launch-d1-d7-retention-go-no-go-gate/), [mobile retention benchmarks 2026](https://appagent.com/?p=61637), [Steam Next Fest 2026 notes](https://ziva.sh/blogs/steam-next-fest-2026), [Steam Next Fest checklist](https://www.steampageanalyzer.com/blog/steam-next-fest-checklist)
- Industry state: [GDC 2026 State of the Game Industry](https://gdconf.com/article/gdc-2026-state-of-the-game-industry-reveals-impact-of-layoffs-generative-ai-and-more/), [Player perceptions of generative AI (Steam reviews)](https://arxiv.org/pdf/2608.11539), [Generative AI in game development: qualitative synthesis](https://arxiv.org/pdf/2509.11898)
