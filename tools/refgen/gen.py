"""CPU SD1.5 + LCM-LoRA + ControlNet(lineart) + IP-Adapter(plus) img2img helper for Aruun reference art."""
import torch, time, json, numpy as np
from PIL import Image
from diffusers import StableDiffusionControlNetImg2ImgPipeline, ControlNetModel, LCMScheduler
from transformers import CLIPVisionModelWithProjection
torch.set_num_threads(4)
_P = {}
NEG = "photo, realistic, 3d render, blurry, lowres, text, watermark, extra eyes, human face, deformed, cartoon outline thick, glossy"
BASE = "stylized hand-painted fantasy creature concept art, flat cel shading, dark ink outline, muted earthy palette, cream background, "

def pipe(cn="lllyasviel/control_v11p_sd15_lineart", ip="ip-adapter-plus_sd15.safetensors"):
    k = (cn, ip)
    if k in _P: return _P[k]
    c = ControlNetModel.from_pretrained(cn, torch_dtype=torch.float32)
    enc = CLIPVisionModelWithProjection.from_pretrained("h94/IP-Adapter", subfolder="models/image_encoder", torch_dtype=torch.float32)
    p = StableDiffusionControlNetImg2ImgPipeline.from_pretrained("stable-diffusion-v1-5/stable-diffusion-v1-5", controlnet=c, image_encoder=enc, safety_checker=None, torch_dtype=torch.float32)
    p.scheduler = LCMScheduler.from_config(p.scheduler.config)
    p.load_lora_weights("latent-consistency/lcm-lora-sdv1-5"); p.fuse_lora()
    p.load_ip_adapter("h94/IP-Adapter", subfolder="models", weight_name=ip)
    _P[k] = p
    return p

def run(init, ctrl, ip_img, prompt, strength=0.5, cn_scale=0.8, ip_scale=0.7, steps=8, seed=1, size=512, neg=NEG, hw=None):
    p = pipe(); p.set_ip_adapter_scale(ip_scale)
    g = torch.Generator().manual_seed(seed)
    t = time.time()
    hw = hw or (size, size)
    out = p(prompt=BASE + prompt, negative_prompt=neg, image=init.resize(hw[::-1]), control_image=ctrl.resize(hw[::-1]), height=hw[0], width=hw[1],
            ip_adapter_image=ip_img, strength=strength, controlnet_conditioning_scale=cn_scale, num_inference_steps=steps,
            guidance_scale=1.5, generator=g).images[0]
    return out, time.time() - t
