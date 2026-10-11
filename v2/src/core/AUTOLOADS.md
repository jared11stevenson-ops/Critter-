# Autoloads to register in v2/project.godot (Lead edits project.godot)

Add under `[autoload]` in THIS ORDER (later ones may use earlier ones). Paths are `res://`; the leading `*` makes it a singleton node.

```ini
[autoload]
Events="*res://src/core/events.gd"
Settings="*res://src/core/settings.gd"
InputActions="*res://src/core/input_actions.gd"
Perf="*res://src/core/perf.gd"
GameSave="*res://src/core/save_service.gd"
```

| Name | Script | Purpose |
|---|---|---|
| `Events` | `src/core/events.gd` | Typed signal bus (bout flow, roster/story, economy, platform). |
| `Settings` | `src/core/settings.gd` | Quality Low/Med/High, fps cap, left-handed, assists, reduce flashing; JSON in `user://v2_settings.json`. |
| `InputActions` | `src/core/input_actions.gd` | Registers InputMap actions (`move_left/right/up/down`, `strike`, `guard`, `grab`, `dodge`, `ability1`, `ability2`, `yield`, `pause`). Touch UI presses the same actions. |
| `Perf` | `src/core/perf.gd` | Frame ring buffer, hitch log, draw/tri stats, overlay, `report_text()`, `save_report()`, `open_report()`. Set `Perf.context = "menu"` or `"play"`. |
| `GameSave` | `src/core/save_service.gd` | Live `RosterState` + `SaveSystem`: `start_new()`, `continue_game()`, `autosave()`. |

Notes
- Do NOT add `class_name` to these five scripts: it would clash with the autoload names. Tests load them with `preload`.
- `PerfReportView` (`class_name`) is the report screen; open it with `Perf.open_report()`.
- Other `class_name`s are global once the project is imported (`godot --headless --path v2 --import`): `RosterState`, `Rack`,
  `CritterInstance`, `BoutOutcome`, `StakesTier`, `StoryRules`, `Economy`, `CareModel`, `Epitaph`, `SaveSystem`, `DeathsLedger`,
  `SaveMigrations`, `PerfStats`, `PerfReportModel`, `PerfReportView`.
- Nothing in `src/core` requires the autoloads to exist except `perf_report_view.gd` (needs `Perf` at runtime), so all tests run without them.
