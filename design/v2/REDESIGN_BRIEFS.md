# CRITTER v2 — Redesign briefs: lore → modelable 3D characters (Lead, 2026-10-11)

**Goal:** better models. The 2D reference sheets do not translate cleanly into Blender, so each character is redesigned from their *lore* with modeling in mind.
Anchors below come from the lore text (`design/v2/lore_text/LORE_BIBLE_v12.txt`) and the creator's direction. The 2D sheets in `tools/source_art/` are *inspiration only*.

## Modeling-first design rules (apply to all seven)
1. **Base pose:** symmetrical A-pose (arms 35° from body), neutral face, weapon in hand or on a socket, feet planted; this is the pose all sheets and the .glb use.
2. **Silhouette:** each of the seven must read as a unique flat black shape at 64 px (existing gate), and as a family: simplified, chunky-heroic proportions (about 3.5-4.5 heads tall), big readable hands/feet, one exaggerated signature feature.
3. **Part budget:** 8-15 major parts (head, neck, torso/thorax, abdomen, upper arms, forearms, hands, thighs, shins, feet, wings/cloak, weapon, signature feature). Each part is a clean shape that a modeler can block out from primitives and refine.
4. **Materials:** 3 main colors + 1 accent + 1 glow per character; flat/toon materials; no baked lighting; textures optional (face, markings).
5. **Insect truth:** use the species' real anatomy as the design language (segmented carapace, joints, antennae, mandibles, wings), stylized not realistic. No human faces, no hair unless the lore says leaf-like strands.
6. **Rig friendliness:** rigid-part or simple skinned; joint pivots at natural insect joints; named sockets: head, hand_R, hand_L, weapon, back, root, ground, plus signature sockets (crown spheres, wing roots).
7. **Budget:** hero <= 6k tris with outline hull, <= 20 draw calls.
8. **Expression:** 6 faces (calm, grin, angry, hurt, scared, dying) readable on a simple face plate or mask.

## Per-character briefs
### Aruun — The Reacher (Red Reaches)
Lore anchors: giraffe-beetle barbarian; elongated build; psionically bonded mace Morrow; famous for destruction, wants to build (Spanwright apprentice); Rage = overdrive that costs his body; shell fractures.
Species language: **giraffe weevil/beetle** (red wing-cases, black head, long thin neck, black legs).
Design direction: tall, broad-shouldered fighter with a long articulated neck and a small beetle head with two swept horn-antennae; red elytra as a shell-cape/pauldron system (plates that can crack); black legs with bridge-truss-like bracing (a Spanwright's ethos); wrapped forearms and rope/chain Spanwright tools; **Morrow**: a heavy studded mace whose head is a pulsing psionic core. Palette family: black, brick red, bone, with a hot orange-red Rage glow. Signature: neck + shell plates + Morrow.
### Cigarra — The Oracle Hopper (Canopy Fold)
Lore anchors: Brazilian treehopper crown of branching black spheres, pale leaflike hair, yellow-green ringed eyes, dark oversized collar, loose clothing, charms, translucent green treehopper-wing cloak; humor as armor; sees possibilities.
Design direction: small, springy, jittery silhouette; the **crown of branching stalks ending in glossy black spheres** is the hero feature (modular, detachable spheres); large ringed eyes; oversized dark hood-collar; baggy layered clothing; leaf-vein translucent wing-cloak that opens for leaps; charms on cords. Palette: deep violet-black, lime/yellow-green, bone-white, glossy black spheres with a gold-green glow. Signature: crown + cloak.
### Bramvex — The Quiet Command (Thornmarch)
Lore anchors: prickly stick insect, ragged membranous wings, field equipment, restrained red insignia, huge thorned weapon "Diplomacy"; a tired, careful sergeant.
Design direction: tall, thin, angular silhouette with long jointed limbs; thorny ridges; a patched field harness with pouches; torn translucent wings folded like a cloak; a **huge thorned club/halberd (Diplomacy)** taller than him; a small red armband/insignia. Palette: bark brown, olive, dusty tan, one red accent. Signature: stick-insect lines + Diplomacy.
### Scarlith — The Fermented Kingpin (Velvet Warrens)
Lore anchors: red-velvet-mite design, cheese/pirate flavor; broker; everything has value.
Design direction: **round, plush red velvet-mite body** (tiny, 12 cm in lore; scale up for gameplay), eight short legs, fuzzy texture suggested by a soft stylized fuzz layer; pirate hat/eyepatch/coat made from cheese-rind and cloth; a barrel or bottle rack on his back; coin purse; gold tooth. Palette: crimson velvet, cheese-gold, wine purple, rind orange. Signature: round fuzzy body + cheese-pirate kit.
### Mollusk — The Weight of Tomorrow (Rainward)
Lore anchors: giant African snail; layered shell carved with journey marks; love of forklifts; gentle, patient, rescue hero.
Design direction: huge calm snail with a thick banded shell carrying carved marks and rescue-crew patches; soft heavy body with a strong foot; stalk eyes with kind, tired faces; a rescue vest/harness with straps; optional small forklift-fork prop on the harness. Palette: shell amber/brown bands, soft olive-grey body, high-vis orange vest accent. Signature: shell with carved marks.
### Zephyr — The Nectar Seeker (Briarwild)
Lore anchors: hummingbird hawk-moth and old-folklore-fairy design philosophy; courier; promises sacred; loves loopholes.
Design direction: small, quick hovering silhouette with fast-looking wing blur shapes, long coiled proboscis (tongue) worn like a scarf, fuzzy moth thorax, antennae like feathered flags, a courier satchel and message tubes; folklore touches (pointed ears from antennae shapes, flower crown or petal skirt). Palette: olive-brown fuzz, orange underwing, nectar-magenta accent, pollen-gold glow. Signature: wings + proboscis + satchel.
### Nyxaris — The Frostbloom Weaver (Frostbloom)
Lore anchors: cryogenic silk and venom; "fully nonhuman"; silk as art, bridges, traps, records; patient until a boundary is crossed; the Cold Archive.
Design direction: elegant, tall spider-weaver silhouette (eight limbs: two arms, six legs or four-and-four), frost-crystal spinnerets, an abdomen patterned like a flower of ice, translucent silk trailing like a train, venom fangs framing the face; ice-flower accents (Frostbloom). Palette: ice-blue, deep indigo, white-silver silk, pink-magenta flower accents. Signature: silk train + frost flower abdomen.

## Deliverables per character (the Character Artist owns these)
1. `design/v2/sheets/<id>_modelsheet.png`: orthographic front/side/back/top on a proportion grid, part breakdown with labels, color swatches, scale reference.
2. `design/v2/sheets/<id>_poses.png`: 8 move poses, 6 expressions.
3. `v2/art_export/<id>.glb`: Blender-ready export of the rig (named nodes, pivots at joints, materials, sockets as Empty nodes), plus `<id>_parts.md` (part list, dimensions in meters, tri counts).
4. A short `design/v2/sheets/<id>_DESIGN.md`: the lore anchors used, what changed from the 2D sheet and why.
