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

## 2026-10 Two fight kinds; roles are styles, not counters (creator)
Only **Blood Bout** (lethal, counts) and **Practice** (nobody dies, nothing counts) exist as player-facing fights. Roles are fighting/ability styles; outcomes must come from skill. Removed the `role_pressure` damage table from the sim and the role bonus on Stalk. Contest tier remains in code only for old save/test compatibility and is not reachable from the UI. Balance target: every pairing near 50% at equal skill.

## 2026-10 Counterplay is allowed, as skill (creator)
Counters are fine when they are performed answers (parry/guard, status answers, cleanse moments), with equal opportunity on both sides; no stat multipliers between styles. Status kits must be rewarded without making counter-less critters lose automatically (Tenacity, parry cleanse). Critters get a 1-3 skill star rating for kit complexity that never reflects power. See design/v2/COUNTERPLAY.md.
