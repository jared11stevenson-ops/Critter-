# Third-party asset licenses (kept current by tools/assets/*.py)

- polyhaven/models/quiver_tree_01: CC0 1.0, by James Ray Cock, Dario Barresi, Rico Cilliers, https://polyhaven.com/a/quiver_tree_01
- polyhaven/models/namaqualand_boulder_02: CC0 1.0, by Greg Zaal, Rico Cilliers, https://polyhaven.com/a/namaqualand_boulder_02
- polyhaven/models/namaqualand_boulder_05: CC0 1.0, by Jenelle van Heerden, Dario Barresi, https://polyhaven.com/a/namaqualand_boulder_05

## Aruun reference generation (design/reference_gen/aruun, tools/refgen)
- Stable Diffusion 1.5: CreativeML OpenRAIL-M (outputs usable commercially, use restrictions apply).
- LCM-LoRA SD1.5: OpenRAIL++-M. ControlNet v1.1 lineart/depth: OpenRAIL. IP-Adapter (h94): Apache-2.0. Real-ESRGAN anime-6B: BSD-3-Clause.
- Excluded: SD-Turbo, Hunyuan and any non-commercial weights.

## Aruun head v6 (tools/modeling/aruun/v6_head)
- Depth Anything V2 SMALL (depth-anything/Depth-Anything-V2-Small-hf, HF): Apache-2.0 (Small only; Base/Large are CC-BY-NC and NOT used). Used as a soft relief prior, inference only, CPU, ~6 s/image. Weights cached in ~/.cache/huggingface (not committed).
- Not used: TripoSR (MIT, skipped by time-box), MiDaS, ZoeDepth.
