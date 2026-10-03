# Aruun hi-res references
Source: tools/source_art/aruun_nerit_sheet.jpg (1280 px). Upscaled 4x with Real-ESRGAN `RealESRGAN_x4plus_anime_6B`
(tools/art_pipeline/esrgan_upscale.py, torch CPU), cut with tools/art_pipeline/hires_cut.py (rembg isnet-anime),
cleaned by tools/art_pipeline/aruun_hires_clean.py.
- front_x4.png, side_x4.png, back_x4.png: ORIGINAL paint, upscaled; only background removed.
  back: the unlabeled grey sketch beside it was dropped (largest component kept).
- front_clean_x4.png: RECONSTRUCTED/EDITED. Morrow (mace head + haft below the right fist) erased; pixels erased are in
  front_morrow_mask.png. On inspection at 4x Morrow does NOT overlap the legs: the haft ends in the fist and the mace
  sits left of the body, so no leg/skirt paint was invented. A short haft stub stays inside the closed fist.
  The front is still a 3/4 pose (not a flat orthographic front); the model uses side/back for proportions.
- Nothing redesigned. Upscaler artefacts: line-art is slightly sharpened/posterised, small dots may be smoothed.
