# CRITTER Core Loop (one page)

**The promise:** you are the Handler. You go down the Gate, solve a place with two critters, bring something back, and the Common visibly changes because of it.

## The loop

```
HUB (Common)            DESCENT (Red Reaches)                 RETURN (Common)
see what's next  ->  Gate -> explore -> fight/scan/rescue ->  recap: what you brought back
one big button       follow ONE arrow, ONE objective          + what the world remembers
                                                              -> upgrade / bond / build
                                                              -> next objective (one big button)
```

Every screen ends by answering "what do I do now?" with exactly one thing: the hub's big bottom button (Meet Mara / Descend / Debrief / Build Habitat) and the single objective line.

## What each thing is FOR (one sentence each)

| Thing | Purpose |
|---|---|
| Descend / Gate Map | Start the next trip into the field; the only way the story moves. |
| Objective banner + arrow | The one thing to do next, with direction and distance; nothing else competes with it. |
| Attack / Abilities / Dash | Win fights and cross obstacles; abilities appear the first time an enemy is near. |
| Swap (partner portrait) | Change which critter you control; each solves different problems. |
| Scan | Learn what a creature or thing is (unlocks Codex and weak points); appears when the valley asks for it. |
| Contain | Rescue a hurt creature (below 30% HP) instead of killing it; feeds the Habitat. |
| Salvage and materials | Crafting/Habitat currency gathered in the field; spent in Gear and the Habitat Wing. |
| Specimens | Creatures you rescued; they live in, and make, the Habitat. |
| Codex | Everything you have scanned or learned, as a reference; never required to progress. |
| Trust / Bonds | How your critters and NPCs feel about you; promises are judged on return (Bonds screen). |
| Ledger (Ledger Wall + return card) | The world's memory of what you did; shown after each descent as "what changed because of you". |
| Gear | Equip what you gathered; appears after the first descent. |
| Rumor Board | Hints at optional side areas you have not found; appears after the first descent. |
| Dominion standing | Reputation with the occupying faction; changes how people react, shown in the recap. |

## The first five minutes

| Min | Player sees | Player does |
|---|---|---|
| 0:00 | Hub with ONE button: "Meet Mara", NEXT banner, Menu. No other places. | Taps Meet Mara; short briefing. |
| 0:45 | Big "Descend" button; Lab/Codex appear, still nothing else. | Taps Descend; Gate Map; Descend. |
| 1:15 | Red Reaches: joystick, ATTACK, objective, an arrow with distance, minimap. Tip: "Drag on the left to move". | Walks toward the arrow. |
| 2:00 | An enemy gets close: Abilities, Dash and partner portrait fade in, tip "Enemy ahead: tap ATTACK". | Fights; learns abilities one tip at a time. |
| 3:00 | Objective turns to "Tap SCAN"; Scan appears with a pulsing ring. | Scans the valley; Codex updates (one short toast). |
| 4:00 | Toasts show one at a time (warnings first); partner tip "Tap your partner's portrait to SWAP" after two ability uses. | Swaps, clears the valley, follows the arrow east. |
| 5:00+ | (Full descent continues; on return) card "What you brought back" + "Next: ...". | Reads recap, taps Continue, taps the one big button. |

## Rules the UI follows

1. One primary action per screen; secondary places live behind "Places".
2. Show a control only when it matters (first enemy, scan prompt, first descent finished); once shown it stays.
3. One toast at a time, max three waiting, warnings jump the queue, each under ~56 characters.
4. Every tip is shown once ever and points at the control with a ring (static ring when Reduce Flashing is on).
5. After each descent: what you brought back, what the world remembers, "Next: ...".
