# Arena / Scene + UI handoff (v2/src/arena, v2/src/ui, v2/src/boot)

Flow: boot.gd (Title -> Select -> Opponent -> Bout -> Result). `godot --path v2` boots to the title.
- `BoutScene.start(BoutConfig)`: CombatSim at fixed 60 Hz accumulator, 2 CritterRigs, `ArenaBuilder` set (<= 5 draws), `BoutCamera` (lock-on, auto-frame, shake/punch), `Hud`, `EntityView`. Emits `finished(result)` after the KO beat.
- Input: `InputProvider` -> `PlayerInput` (keyboard/gamepad via InputActions + `TouchControls`, layouts A buttons / B gestures, left-handed, 6-frame buffer in the sim plus latched presses) and `AIProvider` (CombatAI profiles novice/standard/expert).
- HUD: `HudDraw` (bars, poise rings, tell indicator, pops, banners), `Hud` (yield prompt, pause, perf report), `Ink` batching helper.
- QA: `tools/smoke_bout.sh` (headless, all seven), `tools/shoot_bout.sh` / `tools/shoot_flow.sh` (xvfb screenshots to tools/qa/shots, not committed). Tests: test_arena_*.gd, test_ui_*.gd.
- Boot args after `--`: --autostart=a:b[:profile] --screen=title|select|opponent|settings --layout=A|B --touch --lefty --training --spectate --nointro --speed=N --shot=PATH --shot-at=SEC --fake-result=win|death|defeat|spare|draw
- Keyboard: WASD, J strike (hold heavy), K guard, Space dodge, L grab, U/I abilities (both = Last Stand), Y yield, P pause.
See NEEDS.md for requests and rough edges.
