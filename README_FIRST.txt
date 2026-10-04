CRITTER — The Red Span Survey  ·  v0.8.0 PLAYTEST BUILD
=======================================================
HOW TO OPEN (Godot 4.7 mobile editor)
1. Unzip this file.
2. In Godot: Import -> pick the folder's project.godot -> Import & Edit.
3. First import takes a minute or two (it converts the art and audio).
4. Press Play (the triangle, top right). Landscape mode.

CONTROLS (touch)
- Left thumb: drag anywhere on the left half to move.
- Right side: big button = attack (Aruun's mace / Cigarra's psychic bolt),
  three ability buttons, DASH to dodge.
- Tap a partner portrait (top left) to SWAP between Aruun and Cigarra.
- SCAN (top right): identify creatures; it tells you what's wildlife, sapient, or Dominion.
- A context button appears for Interact / Contain (capture a weakened wild creature).
- Hub: drag to look around, tap glowing labels and characters.

THE SLICE (about 15-25 min)
Terrarium One briefing -> descend to the Red Reaches -> fracture valley -> Cigarra's gap leap ->
Spanwright waystation -> Thoughtstone boulder -> Dominion drill site (try scanning a beetle) ->
the Ochre Span -> AUGUR-7 boss -> a choice -> home -> build a Habitat -> ending.
Play it twice: the choice at the end changes the bridge, the dialogue and your Terrarium.

KNOWN PLACEHOLDERS
- Music is a temporary score until Youngyumeprophecy tracks are delivered.
- Balance is first-pass. Tell me everything: too hard, too easy, confusing, ugly, boring, great.

NOTES FOR THE DIRECTOR
Send notes in any form: "the boss is too hard", screenshots, voice-to-text, whatever.

NEW IN v0.7.0
- World realism pass: textured PBR terrain and cliffs, real 3D rocks/trees/grass, no ink outlines,
  per-area lighting, rim light on characters, dust motes, Dominion work lights, hub light pools.
- Text audit: spelling standardized to the bible's American English; 4 lore-accuracy fixes in dialogue.
- Godot 4.7 is now the official engine.
- PREVIEW: 3D Aruun model (rigged, 15 animations). Turn on in Settings -> "3D character models (preview)".
  Still being refined; Cigarra's 3D model is next. Tell me how Aruun looks/moves on your phone.


NEW IN v0.8.0
- LAG FIX: Graphics quality presets in Settings (Auto / Low / Medium / High) and a 30 / 60 FPS cap.
  Auto starts at Medium on phones and drops itself to Low if your phone can't keep up.
  If it still lags: Settings -> Graphics -> Low, and FPS cap -> 30.
- Triangle count roughly 40% lower (222k -> ~140k) with chunked scatter, cheaper shaders and throttled CPU work.
- Motion-capture animation for 3D Aruun (19 clips; hits land on the swing's impact frame; Gravity Pull is hold-to-slam).
  3D Aruun is still an OPTIONAL PREVIEW (Settings -> "3D character models (preview)"): the motion is much better than
  the cut-out's, but the model itself still reads pale at gameplay distance. Tell me what you think.
- Sharper character cut-outs and portraits (4x AI upscale of your sheets).
- Cigarra has no 3D model yet, so with the preview on she stays a cut-out.
