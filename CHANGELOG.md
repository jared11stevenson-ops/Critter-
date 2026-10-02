# CRITTER — Changelog

Each version lists real, individually verifiable changes, grouped by team:
**[ART]** Agent 1 (art, assets, animation, lighting) · **[GAME]** Agent 2 (gameplay, UI/UX, balance) ·
**[LEAD]** direction, canon, integration, debugging, polish.

## v0.0.0 — Foundation
- [LEAD] Read the full CRITTER Master Lore Bible v12 (96k chars) and all 37 embedded visual references.
- [LEAD] Continuity audit: 8 conflicts resolved (Nerit v2, Mollusk Hawaiian, Solmara v2, Mara illustrated, Cigarra 165 cm, Scambril cut).
- [LEAD] Godot 4 project skeleton (Compatibility renderer, landscape, touch emulation, 1280×720 base).
- [LEAD] Toolchain: Godot 4.7.2 + 4.3 headless validation, Xvfb screenshot QA, packaging script.
- [LEAD] Canon database `game/canon/canon.json` (12 characters, 10 abilities, 5 species, 4 places).
- [LEAD] Vertical slice GDD "The Red Span Survey" (design/GDD.md).
- [LEAD] Art ⇄ Gameplay interface contracts (design/CONTRACTS.md).
- [LEAD] Red Reaches level layout data (9 floors, 2 chasms, 8 structures, 20 markers, 9 triggers, 10 pickups).
- [LEAD] Core autoloads: Events bus, Canon, GameState (flags/trust/items/specimens/codex/save), Audio director, Router (fade + Gate "Tilt" transitions).
- [LEAD] Input map for touch, keyboard and gamepad (incl. Dash).
- [LEAD] QA autoload: scripted input playback + timed screenshots (inert in normal play).
- [LEAD] Open-licensed fonts (OFL): Permanent Marker, Kalam, Barlow Condensed, Cinzel.
