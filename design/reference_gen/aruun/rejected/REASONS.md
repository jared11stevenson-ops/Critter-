# Rejected generations (SD1.5 + LCM 8 steps, seed 1, 512 px)
- calm_i2i_only_s45.png: img2img only, strength .45 - cartoon restyle; snout shape and fringe lost.
- calm_ip_s55.png: IP-Adapter(self) strength .55 - helmet-like head, fringe lost, plates re-invented.
- rage_cn_ip_s50.png / rage_cn_ip_s70.png: lineart ControlNet 1.0 + IP .6 - silhouette held but palette drifted (pink tongue turned brown, cream face plate turned white-outlined, olive fringe lost).
- rage_cn_ip_s30_marginal.png: strength .3 - design mostly held, tongue less pink, fringe simplified; no gain over the plain upscale, so not used.
- body_front_try1_greybox_s80.png: greybox clay front as init + silhouette lineart CN 1.0 + IP-Adapter(back view) .8, strength .8, 544x768, 73 s. Output is a flat brown blob with the clay's lumpy slabs; no costume, no horns, no discs. The clay (visual hull of side+back) is far too crude as a condition for SD1.5 at this resolution. Deliverables 2 (true ortho front) and 4 (A-pose) cannot be produced on-model this way.
