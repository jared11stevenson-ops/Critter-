# Dr. Mara Venn - modelling / art spec
Source: tools/source_art/mara_sheet.jpg (1400 px, "illustrated - approved for game"), lore bible v12, canon.json.
Hi-res views: hires/{front,side,back}_hd.png = the in-game billboard cut at full Real-ESRGAN x4 detail (original
paint, background removed, nothing redrawn). Boards: turnaround.png (with 170 cm bar), palette.json/png
(k-means per view), expressions.png (the 6 in-game portraits = sheet head studies).

## Identity (sheet text)
Physicist / Explorer / Project Lead. Age 34. **Height 5'7" (170 cm)** - canon.json 1.7 m (match).
Build athletic/lean. Lead Physicist (Scale-State), specialty Gate Technology / Scale Physics. Faction: Stewardship
Coalition (canon.json). Quote: "Curiosity always wins. It just usually costs more than people expect."

## Field outfit (turnaround = the game look)
- Hair: dark brown, very messy high bun with loose strands framing the face; strands fall over the forehead.
- Face: green-brown eyes ("highly expressive"), freckles across nose and cheeks, small scar on the LEFT cheek
  (lab accident). Warm light-brown skin.
- Suit: light grey-beige expedition jumpsuit; black harness straps crossing chest, waist and thighs; black upper-arm
  bands; round Stewardship patch (dark disc, white emblem) on the LEFT shoulder.
- Black gloves (fingerless look on the hero art), black knee pads, black lace-up combat boots, trouser cuffs
  bloused over the boot tops.
- Large black Expedition Pack with orange accent strips and pouches (back view: the pack covers most of the back);
  Field Tablet carried in the hand/on hip (hero art), Watch (enviro + vitals) on the wrist.
- Optional: Helmet (sealed enviro) - white/grey with orange visor rim; not worn in the turnaround.
- Tattoo (minimal, forearm, not publicly discussed) - do not show in the field outfit.

## Other outfits on the sheet (hub / cutscene variants, not cut yet)
- Casual / Base: oversized black hoodie (white circular logo), olive cargo pants, mug in hand.
- Lab / Ship: black tee, hair up, at a terminal.

## Palette
Sheet swatches: near-black, dark brown, mid grey, olive green, dark green, orange, blue. Measured from the cut:
see palette.json (dominant #2e2624 black-brown straps, #ac8e77 suit beige, #d2baa4 highlights).
The in-game portrait frame colour for Mara is set in UI (not art).

## Silhouette / modelling notes
Upright, lean; silhouette read = bun + big backpack + bloused trousers into heavy boots. Asymmetry: shoulder patch
on the left, scar on the left cheek. Hands often gloved; she touches her left index finger when thinking (quirk -
idle animation idea). Budget suggestion if ever 3D: <= 15k tris, one 1024-2048 texture set.

## Known limitations of the source
The FRONT turnaround view is a 3/4 pose facing screen-right (so the billboard "front" is 3/4); there is no
true orthographic front. All cuts are from the 1400 px sheet (figure ~320 px tall), upscaled x4 by ESRGAN:
fine straps/buckles are reconstructed by the upscaler, not painted at that size by the artist.
