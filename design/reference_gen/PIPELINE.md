# Aruun reference-gen pipeline (CPU box: 4 cores, 15 GB, no GPU; box shared with other agents, load avg 10-15 during tests so timings are pessimistic)

| Component | Source / license | Status |
|---|---|---|
| diffusers 0.40 + SD 1.5 (stable-diffusion-v1-5/stable-diffusion-v1-5) | CreativeML OpenRAIL-M | works (fp32, 3.4 GB unet) |
| LCM-LoRA SD1.5 (latent-consistency/lcm-lora-sdv1-5) | OpenRAIL++-M | works, 8 steps |
| ControlNet lineart / depth v1.1 (lllyasviel) | OpenRAIL | lineart loaded; depth downloaded, not yet used |
| IP-Adapter plus sd15 + ViT-H encoder (h94) | Apache-2.0 | works |
| Real-ESRGAN x4plus_anime_6B | BSD-3 | works: 520x520 -> 2080x2080 in ~4 min under load (tile 200) |
| SD-Turbo / Hunyuan / other non-commercial | excluded | - |

Disk is tight (about 4 GB free after models); no LoRA training attempted yet.

## A/B on the CALM face (512 px, 8 LCM steps, CPU, under contention)
| Run | Settings | Result | Time |
|---|---|---|---|
| A img2img only | strength .45, no CN, no IP | face-like but flattened cartoon; snout shape, fringe, plate layering lost | ~2 min incl. model load |
| B + IP-Adapter(self) | strength .55, ip .8 | similar cartoon drift, helmet-like, fringe lost | ~5 min (load 10+) |
| C/D + lineart CN | cancelled (box saturated) | not evaluated | - |
| Real-ESRGAN anime-6B only | x4 | faithful, clean, in-style flat cel | ~4 min |

Finding: the source sheet is only 1280x853; each expression face is ~60 px. Diffusion at strength >= .45 changes the design (rejected, see rejected/). Upscale + compositing of original paint keeps the design locked, so it is the default; diffusion is reserved for low-strength cleanup and for regions that must be invented (marked yellow in derivation overlays).
