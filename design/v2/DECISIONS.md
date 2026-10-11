# Open decisions (each with the Lead's recommended default; work proceeds on the default)

| # | Question | Default |
|---|---|---|
| D1 | Bouts are 1v1; you own up to 7 jars; team bouts are 3 of 7 sequential | Yes |
| D2 | Stakes tiers: Sparring / Contest / Blood Bout | Yes |
| D3 | Yield or Last Stand at low Vitality | Yes (signature moment) |
| D4 | Combat triangle: Strike > Grab > Guard > Strike, plus Dodge and Parry (not directional guard) | Yes |
| D5 | Touch scheme: A buttons, B gestures; test both | Test both |
| D6 | Seven original critters (placeholder designs) | Yes, creator will designate changes |
| D7 | Life Story: 7 chapters per critter, unlocked by survival milestones | Yes |
| D8 | Online PvP | After launch (the sim is deterministic) |
| D9 | Breeding / metamorphosis | Tier 2 |
| D10 | Lore | Minimal premise now; creator rewrites later |

## Platform Engineer's questions (Lead's answers, 2026-10-11)
- Ownership table updated in INTERFACES.md (platform owns v2/tools except sim; Lead may edit any folder).
- Bond thresholds 5/15/30/60/100 and Contest scar rule (loss/yield/<15% vitality, cap 3): accepted as defaults; creator may change.
- Per-critter story overrides and personal trials: to be filled when the Life Story content is written (hook: RosterState.complete_trial).
- Reinstall wipes the deaths ledger: accepted for now; cloud save is a Tier 2 item.
