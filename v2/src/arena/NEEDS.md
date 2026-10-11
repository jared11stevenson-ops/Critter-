# Arena / UI notes for the Lead (requests to other owners, rough edges)

## Requests
- **project.godot version bump** (Lead only): suggest `config/version="0.2.0"` for the first playable duel build.
- **Platform (core Settings):** UI-only prefs (touch layout A/B, touch UI auto/on/off, last picks, AI profile) live in `user://v2_ui_prefs.json` via `UiPrefs`; fold into `Settings` when convenient.
- **Display font:** UI uses the engine fallback font emboldened (`UiStyle.font()`); a licensed hand-lettered display font (Bangers class) must be added with ASSET_LICENSES. One place to change.
- **Combat:** no change needed. Training is `stakes 0` (no killing blow), not an invulnerability toggle; if "can't be KO'd" is wanted, the sim needs a `no_death` flag.
- **Character Artist:** rig dt must stay <= ~1/30 (springs blew up to NaN at dt 0.1; BoutScene clamps). Plates: BoutScene passes crack tiers computed from `plates` left.
- **Draw calls:** HUD+touch use ~42 calls thanks to `Ink` (textured-rect batching); every distinct text size/outline adds 2 calls, so keep HUD font sizes in {14,18,26,34,44}.

## Rough edges
- Backdrop ruins read as brown blocks in fog; needs a lookdev pass. Sun rim light is weak on the critters.
- Camera is fixed-shoulder (right); no manual lock-switch (1v1 only). Camera can sit over the void on the player's side of the ring.
- Touch controls verified by simulated events and screenshots, NOT yet on a real phone; hold threshold (11 ticks) and button sizes need a phone pass. Tap-light fires on release (up to ~180 ms later) by design of tap-vs-hold.
- Entity visuals (projectiles / zones / phantoms) are plain spheres and discs; ability VFX beyond the rig's own are missing. No audio.
- Safe-area handling uses DisplayServer safe area; untested on a notched device.
- Perf numbers are from software GL (llvmpipe); frame times there are meaningless, draw calls and tris are real.
- Character select uses flat palette portraits; the live preview shows one critter at a time.
