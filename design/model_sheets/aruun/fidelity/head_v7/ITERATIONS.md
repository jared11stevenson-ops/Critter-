# head v7 iteration log (candid critiques)

Loop per iteration: `tools/modeling/aruun/v7_head/iter.sh TAG` = build (build_head7.py) -> Cycles CPU clay + colour "parts" + object-ID renders from cameras that match the reference crops exactly (side crop of v2 side tile, calm face tile, v2 back tile) -> overlay (cyan = model silhouette, green = plate edges drawn on the reference) -> `compare_<view>.png` (top-left reference, top-right overlay, bottom-left clay, bottom-right colour parts). `iterN/` keeps the compare sheets (final/ has the finished set). Head-band IoU numbers = whole scene with the head swapped into LOCKED_P1d, band 1.75-2.0 m, v2 masks.

## iter1 (compare sheets in iter1/)
Looked at: side + front + back overlays. Plates were ray-projected onto an 8-sided cage and subdivided; Solidify with even-offset made spikes (a plate at L=-0.89 m, found by listing object bboxes).
Differences vs reference, ranked:
1. Plates crumple into slivers wherever the polygon leaves the cage silhouette (rays miss, fall back to nearest point) -> unreadable clay.
2. Cage is a fat box; lower cage + mandible overlap into one slab; mouth/jaw does not hook.
3. Fringe cards are long vertical sticks seen edge-on; a fringe strand hangs where the reference has none.
4. Eyes sit on the exact side silhouette (ok in side) but are invisible from the front (reference eyes sit in big dark sockets facing forward-out).
5. Tines placed at U 2.06 (side strip) - wrong, back/front tiles put the bone tines at U ~2.10-2.13.
Fixes: even-offset off, out-of-silhouette vertices pulled inside, cage bottom raised, fringe orientation.

## iter2 (not kept) -> iter3 (iter3/)
iter3: cage rings got separate upper/lower half-widths (wide forehead, narrow muzzle); eyes became angular raised sockets + almond eye + pupil, axis 60 deg off forward; fringe re-planned as wings/hangs; tines moved.
Critique: (1) orange crown shield still a crumpled shard pile because it is front-projected on the narrowing snout cage; stepped crown plates overlay the shield; (2) sockets now read correctly in front and side (largest gain); (3) fringe wings far longer than the reference silhouette (cyan outside ref at left); (4) back view: tines are too low (U 2.04 vs 2.10 in ref), the nape cream mark of the reference is missing; (5) jaw still a horizontal bar, ref lower contour rises to a throat concave at F 0.10-0.14 and then drops to the hook.

## iter4 (iter4/)
Per-plate subdivision lengths (big plates flat), stepped crown plates clipped away from the shield strip (|s|<0.04), shorter fringe.
Critique: nose/shield still spiky: the problem is ray projection onto a sloped faceted cage, not subdivision. Side-view clay is calmer.

## iter5 (iter5/)
Front plates (crown_shield, nose_pad, cheek_front, nostrils) no longer ray-projected: they sit on an analytic forehead/snout surface F = F_front(U) - k s^2 read from the side silhouette ("surf" plates). Cage front shortened so plates stand proud.
Critique (side+front): shield is now a crisp orange block, cream cheek plates and the nose pad are readable, dark sockets read like the face tile. Still wrong, ranked: (1) snout is a blunt box instead of the reference's long slim drooping muzzle with the notch between the shield knob and the jaw hook; (2) mandible is a straight bar with a visible mouth slit; reference jaw is a hooked red wedge tucked under the snout; (3) front: cream cheek plates too big/low, tiny sliver triangles at the shield V-tip/nostril; (4) cheek red/brow strip plates are still ray-projected so their edges are only roughly the painted ones; (5) tan back strands/tines in the side view are only suggested.

## iter6-9 (measurement-driven, only `final/` kept)
Mandible bottom raised in the throat (rings 660/715), cranium top +8 px, tines lowered to U ~2.11, cage front bottom raised to open the notch under the shield knob, fringe wings shortened (they showed as blue spikes in the back band diff), flap/hang strands removed or trimmed after they cost back-band IoU (0.848 -> 0.828 -> back to 0.848).
Final state critique (final/compare_*.png, band_diff.png): see HANDOFF.md "known wrong".
