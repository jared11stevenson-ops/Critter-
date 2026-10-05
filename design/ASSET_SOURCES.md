# Asset sources and licensing rules (Lead)

We use other engines' and communities' content to speed up the game, but only content we are licensed to ship.

**Allowed:** CC0 / public domain; MIT/Apache/BSD; CC-BY (credit in CREDITS.md + design/ASSET_LICENSES.md); marketplace assets whose license
explicitly allows use in any engine and in commercial games (record the license text/URL).
**Not allowed:** anything ripped from commercial games or from game files (Unreal-based games included), CC-NC, GPL/AGPL/EUPL,
editor-only/Unreal-Engine-only licensed content (Fab "UE only" items), assets with unclear terms.
Every imported asset gets a line in design/ASSET_LICENSES.md (tools/assets/*.py do this automatically).

## Reachable from this container (checked 2026-10-05)
| Source | License | Use | Notes |
|---|---|---|---|
| Poly Haven (API) | CC0 | PBR textures, HDRI skies, scanned rocks/plants/props | `tools/assets/polyhaven.py`; scans are high-poly, decimate for mobile |
| ambientCG | CC0 | PBR materials | |
| Kenney, Quaternius | CC0 | stylized props, characters, kits | |
| OpenGameArt | mixed (check each) | misc | |
| Sketchfab | mixed (check each) | models | download needs an API key |
| Mixamo | Adobe terms (free, commercial use OK, no redistribution of raw files) | humanoid animations/retarget source | needs login |
| Fab / Epic Marketplace | per-asset | blocked from this container (HTTP 403) | creator can download legit "any engine" assets and add them to the repo (LFS) |

## How characters use outside content
Hero/NPC characters must match our reference sheets, so outside meshes are only starting points (base bodies, props, hands, cloth)
that are reworked in Blender and recorded in the license ledger.
