#!/usr/bin/env python3
"""Composite the user's logo onto the logo-less dial bases -> final dial resources.

Reads  prebuilt/dial_widget_base.png , prebuilt/dial_plain_base.png   (committed, logo-free)
       assets/logo.png                                                (the user's logo; optional)
Writes resources/drawables/dial_widget.png , resources/drawables/dial_plain.png

Pure Pillow (no numpy / ImageMagick / fonts) so it runs anywhere Python + Pillow do.
The logo is fit-centered into a fixed slot below the 12. White-on-transparent OR opaque
art both work; if assets/logo.png is missing, the slot is simply left empty.
"""
from PIL import Image
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)

LOGO = "assets/logo.png"
# logo slot in final 454-px dial coords (derived from the dial geometry)
SLOT_CX, SLOT_CY = 227.0, 122.67      # horizontal center line, below the 12
SLOT_W,  SLOT_H  = 103.5, 51.75       # max width / height; logo scaled to fit, aspect kept

def logo_mask():
    """Return a white-ink alpha mask of the logo, cropped to the mark, or None."""
    if not os.path.exists(LOGO):
        return None
    src = Image.open(LOGO).convert("RGBA")
    alpha = src.getchannel("A")
    if alpha.getextrema()[0] < 250:                 # has transparency -> alpha is the shape
        mask = alpha
    else:                                           # opaque art -> dark pixels are the ink
        mask = src.convert("L").point(lambda v: 255 - v)
    bb = mask.getbbox()
    return mask.crop(bb) if bb else None

def build(base_path, out_path, mask):
    dial = Image.open(base_path).convert("L")
    if mask is not None:
        sc = min(SLOT_W / mask.width, SLOT_H / mask.height)
        w = max(1, round(mask.width * sc)); h = max(1, round(mask.height * sc))
        m = mask.resize((w, h), Image.LANCZOS)
        dial.paste(255, (int(SLOT_CX - w / 2), int(SLOT_CY - h / 2)), m)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    dial.convert("P", palette=Image.ADAPTIVE, colors=16).save(out_path)

mask = logo_mask()
build("prebuilt/dial_widget_base.png", "resources/drawables/dial_widget.png", mask)
build("prebuilt/dial_plain_base.png",  "resources/drawables/dial_plain.png",  mask)
print("place_logo: " + ("logo composited" if mask is not None else "no assets/logo.png -> empty slot"))
