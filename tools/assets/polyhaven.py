#!/usr/bin/env python3
"""Fetch CC0 assets from Poly Haven (https://polyhaven.com, license CC0 1.0) into the project.

  python3 tools/assets/polyhaven.py search models rock          # list ids matching a category/tag/name
  python3 tools/assets/polyhaven.py get models boulder_01 [1k]  # download glTF + textures (to WebP) -> game/art/assets/polyhaven/<id>/
  python3 tools/assets/polyhaven.py get textures rock_boulder_dry [1k]   # PBR set (diff/nor_gl/arm) -> WebP
  python3 tools/assets/polyhaven.py get hdris kloofendal_48d_partly_cloudy_puresky [1k]   # sky, converted to WebP (LDR preview)

Every download appends a line to design/ASSET_LICENSES.md (source, author, license). Only CC0 content is fetched.
"""
import json, os, sys, urllib.request, io
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
OUT = os.path.join(ROOT, "game", "art", "assets", "polyhaven")
LIC = os.path.join(ROOT, "design", "ASSET_LICENSES.md")
UA = {"User-Agent": "critter-asset-tool"}


def api(path):
    return json.load(urllib.request.urlopen(urllib.request.Request("https://api.polyhaven.com" + path, headers=UA), timeout=30))


def fetch(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=120).read()


def log_license(kind, aid, info):
    authors = ", ".join((info.get("authors") or {}).keys()) or "Poly Haven"
    line = f"- polyhaven/{kind}/{aid}: CC0 1.0, by {authors}, https://polyhaven.com/a/{aid}\n"
    os.makedirs(os.path.dirname(LIC), exist_ok=True)
    if not os.path.exists(LIC):
        open(LIC, "w").write("# Third-party asset licenses (kept current by tools/assets/*.py)\n\n")
    if line not in open(LIC).read():
        open(LIC, "a").write(line)


def webp(data, dest, maxsize=1024, quality=82):
    im = Image.open(io.BytesIO(data))
    im.thumbnail((maxsize, maxsize))
    if im.mode not in ("RGB", "RGBA"):
        im = im.convert("RGB")
    im.save(dest, "WEBP", quality=quality, method=6)


def search(kind, q):
    q = q.lower()
    for aid, v in api(f"/assets?t={kind}").items():
        hay = " ".join([aid, v.get("name", "")] + (v.get("categories") or []) + (v.get("tags") or [])).lower()
        if q in hay:
            print(aid, "|", v.get("name"), "|", ",".join(v.get("categories") or []))


def get(kind, aid, res="1k"):
    info = api(f"/info/{aid}")
    files = api(f"/files/{aid}")
    dest = os.path.join(OUT, kind, aid)
    os.makedirs(dest, exist_ok=True)
    if kind == "models":
        g = files["gltf"][res]["gltf"]
        gltf = json.loads(fetch(g["url"]))
        for rel, meta in g["include"].items():
            data = fetch(meta["url"])
            if rel.lower().endswith((".jpg", ".png")):
                name = os.path.splitext(os.path.basename(rel))[0] + ".webp"
                webp(data, os.path.join(dest, name))
                for img in gltf.get("images", []):
                    if img.get("uri") == rel:
                        img["uri"] = name
            else:
                open(os.path.join(dest, os.path.basename(rel)), "wb").write(data)
        json.dump(gltf, open(os.path.join(dest, aid + ".gltf"), "w"))
    elif kind == "textures":
        for mp in ("Diffuse", "nor_gl", "arm", "Displacement"):
            if mp in files and res in files[mp]:
                u = files[mp][res].get("jpg", files[mp][res].get("png"))["url"]
                webp(fetch(u), os.path.join(dest, f"{aid}_{mp.lower()}.webp"))
    elif kind == "hdris":
        u = files["tonemapped"]["url"] if "tonemapped" in files else None
        if u:
            webp(fetch(u), os.path.join(dest, aid + "_sky.webp"), maxsize=2048)
    log_license(kind, aid, info)
    print("ok", dest)


if __name__ == "__main__":
    a = sys.argv[1:]
    if len(a) >= 3 and a[0] == "search":
        search(a[1], a[2])
    elif len(a) >= 3 and a[0] == "get":
        get(a[1], a[2], a[3] if len(a) > 3 else "1k")
    else:
        print(__doc__)
