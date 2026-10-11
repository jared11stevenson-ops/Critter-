# Playtest notes (creator)

## v0.2.0 on Galaxy S25 (Adreno 830, run inside Godot editor, Quality 1, cap 60) — 2026-10-11
**Perf report:** 59.8 fps avg, p50 16.7 ms, p95 17.7, p99 26.4; play: avg 16.8 ms, 0.2% slow; worst frames: 228 ms (scene load), 92-995 ms (menu/boot); draws avg 85 peak 160 (HUD+3D, budget 150 flagship), tris 26k, script 12.6 ms (debug editor build), nodes 131. Verdict: smooth; spikes only at load/menu.
**Feedback:** (1) combat movement too slow; (2) every ability needs unique VFX; (3) each character has 3 main abilities plus separate Dodge and Guard buttons; (4) bigger ring; (5) more fluid combat and animations. "Good start."
**Actions:** Combat: movement speeds, action recovery/cancel windows, 3rd ability per critter, bigger arenas. UI: new button layout. Art: unique VFX per ability + animation fluidity (blending, anticipation/follow-through).
**Third abilities (lore-sourced, from LORE_MOVES.md):** Aruun: Reaching Strike / Gravity Pull / Beetle Rage. Cigarra: Premonition / False Memory / Puppet Thought. Bramvex: Ghost / Ground Prep / Detain. Scarlith: Ferment / Decompose / Cultivate. Mollusk: Inertia Field / Borrowed Seconds / Lift. Zephyr: Gust / Pollen / Promise. Nyxaris: Boundary / Venom Fang / Cocoon.
**Controls:** Strike (tap/hold), Guard, Dodge, Ability 1-3, Grab = Guard+Strike together (universal; swipe forward on layout B), Last Stand button appears when available, Yield by long-press on pause.
